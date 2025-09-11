# Lambda + DynamoDB + Bedrock + RAG 処理フロー

このドキュメントは、Lambda 関数で DynamoDB と Bedrock を使った問い合わせ回答生成の処理フローとデータ受け渡しについてまとめたものです。

---

## 1. 全体処理フロー
### CreateAnswer関数

1. **Lambda が呼ばれる**

   * `event` に `id` が含まれていることをチェック
   * `id` がなければ 400 エラーを返す

2. **DynamoDB から問い合わせ内容を取得**

   * `table.get_item(Key={'id': inquiry_id})`
   * 取得したデータの `reviewText` を取り出す

3. **RAG（ナレッジベース検索）**

   * `knowledge_base_id` が設定されている場合、Bedrock Agent Runtime を使用して検索
   * 検索クエリは `reviewText`
   * ベクトル検索の場合、ナレッジベース内で類似度の高い結果を取得
   * 取得結果から本文をまとめて `context_text` に格納

4. **プロンプト作成**

   * `reviewText` と `context_text` を組み合わせて `prompt` を作成

     ```text
     ホテル情報：
     {context_text}

     お客様の問い合わせ：
     {review_text}
     ```

5. **Bedrock Runtime で回答生成**

   * `request_body` に `prompt` をセット
   * `bedrock_runtime.invoke_model(modelId=model_id, body=json.dumps(request_body))` でモデル呼び出し
   * 返却された JSON から `generated_answer = response_body['content'][0]['text']` を取得

6. **DynamoDB に回答を保存**

   * `update_item` を使用し、`answer` と `updatedAt` を更新
   * 既存フィールドは保持される

7. **レスポンス返却**

   * 生成した回答と問い合わせIDを JSON で返す

---

## 2. データ受け渡しフロー

```text
event['id']  ← Lambda に渡される問い合わせID
    │
    ▼
DynamoDB から取得
review_text = inquiry_item['reviewText']
    │
    ▼
RAG検索（ナレッジベース）
retrievalResults → context_text にまとめる
    │
    ▼
prompt = f"{context_text}\n{review_text}"  ← 文字列化
    │
    ▼
Bedrock Runtime に渡す
request_body = {"messages":[{"role":"user","content":prompt}]} 
    │
    ▼
Bedrock が回答生成
response_body['content'][0]['text'] → generated_answer
    │
    ▼
DynamoDB に保存
update_itemで answer = generated_answer, updatedAt = timestamp
    │
    ▼
Lambda が 200 JSON レスポンスとして返す
```
