## 概要
[terrafomr-project-5](https://github.com/sae-maruyama/terraform-project-5.git) にて作成した問い合わせ受付機能（API Gateway + Lambda + DynamoDB）に対して、Amazon Bedrock を活用し、生成AIを用いて自動で回答を生成する仕組みを追加する
プライベートな情報にも対応できるよう、S3バケットにRAGデータを保存し、それを基に回答を生成する
Lambda関数`CreateAnswer`と`JudgeCategory`を作成する

## 前提
1. **RAGデータ**
一例としてホテルの営業時間、住所、チェックイン・チェックアウト時間等の情報をまとめたファイル（hotelinfo.md）をS3バケットにアップロードし、RAGデータとして利用可能にする
2. **BedRock**
基盤モデル：anthropic.claude-3-sonnet-20240229-v1:0
ナレッジベース：埋め込みモデル（cohere.embed-multilingual-v3）・ベクトルデータベース（open search serverledd）・データソース（hotelinfo.md）

## 構成
### CreateAnswer関数（問い合わせ回答生成）

1. **Lambda が呼ばれる**
   - `event` に `id` が含まれていることをチェック
   - `id` がなければ 400 エラーを返す

2. **DynamoDB から問い合わせ内容を取得**
   - `table.get_item(Key={'id': inquiry_id})`
   - 取得したデータの `reviewText` を取り出す

3. **RAG（ナレッジベース検索）**
   - `knowledge_base_id` が設定されている場合、Bedrock Agent Runtime を使用して検索
   - 検索クエリは `reviewText`
   - ベクトル検索により類似度の高い結果を取得
   - 取得結果から本文をまとめて `context_text` に格納

4. **プロンプト作成**
   - `reviewText` と `context_text` を組み合わせて `prompt` を作成

     ```text
     ホテル情報：
     {context_text}

     お客様の問い合わせ：
     {review_text}
     ```

5. **Bedrock Runtime で回答生成**
   - `request_body` に `prompt` をセット
   - `bedrock_runtime.invoke_model(modelId=model_id, body=json.dumps(request_body))` でモデル呼び出し
   - 返却された JSON から `generated_answer = response_body['content'][0]['text']` を取得

6. **DynamoDB に回答を保存**
   - `update_item` を使用し、`answer` と `updatedAt` を更新
   - 既存フィールドは保持される

7. **レスポンス返却**
   - 生成した回答と問い合わせIDを JSON で返す

---

### JudgeCategory関数（問い合わせ分類）

1. **Lambda が呼ばれる**
   - `event` に `id` が含まれていることをチェック
   - `id` がなければ 400 エラーを返す

2. **DynamoDB から問い合わせ内容を取得**
   - `table.get_item(Key={'id': inquiry_id})`
   - 取得したデータの `reviewText` を取り出す
   - 存在しなければ 404 エラー、空であれば 400 エラーを返す

3. **分類用プロンプト作成**
   - 以下のカテゴリから必ず1つを選択するように指示
     - 質問
     - 改善要望
     - ポジティブな感想
     - ネガティブな感想
     - その他
   - 回答はカテゴリ名のみ

4. **Bedrock Runtime で分類**
   - `request_body` にプロンプトをセット
   - `bedrock_runtime.invoke_model(modelId=model_id, body=json.dumps(request_body))` でモデル呼び出し
   - 出力結果を `raw_category = response_body['content'][0]['text'].strip()` として取得

5. **分類結果を正規化**
   - 有効なカテゴリ一覧 `['質問', '改善要望', 'ポジティブな感想', 'ネガティブな感想', 'その他']`
   - `raw_category` がいずれかに部分一致すれば採用、なければ `"その他"`

6. **DynamoDB に分類結果を保存**
   - `update_item` を使用し、`Category` と `updatedAt` を更新
   - 既存フィールドは保持される

7. **レスポンス返却**
   - 分類結果と問い合わせIDを JSON で返す

---
