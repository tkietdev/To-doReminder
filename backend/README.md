# TaskMate Backend

Backend Express.js + MySQL cho app Flutter `To-doReminder`.

## Phan tich Flutter

App hien tai dung Firebase Auth va Firestore. Cac model can map sang API:

- `UserModel`: `id`, `email`, `name`, `createdAt`
- `Task`: `id`, `title`, `description`, `deadline`, `priority`, `isCompleted`, `userId`, `groupId`, `memberIds`, `createdAt`, `updatedAt`
- `Group`: `id`, `name`, `description`, `creatorId`, `memberIds`, `createdAt`, `updatedAt`

API giu dung ten field dang camelCase nhu Flutter. MySQL dung snake_case trong database.

## Cau truc thu muc

```text
backend/
  database/schema.sql
  src/
    config/
    controllers/
    middleware/
    models/
    routes/
    services/
    utils/
    app.js
    server.js
  .env.example
  package.json
```

## Cai dat

1. Tao file `.env` tu mau:

```bash
copy .env.example .env
```

2. Sua `.env`:

```env
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_NAME=taskmate_db
DB_USER=root
DB_PASSWORD=your_mysql_password
JWT_SECRET=replace_with_a_long_random_secret
JWT_EXPIRES_IN=7d
```

Khi chay backend, server tu tao database theo `DB_NAME` va cac bang/index trong `database/schema.sql` neu chua ton tai.

3. Cai package va chay:

```bash
npm install
npm run dev
```

Production:

```bash
npm start
```

## Response JSON thong nhat

Thanh cong:

```json
{
  "success": true,
  "message": "OK",
  "data": {},
  "error": null
}
```

Loi:

```json
{
  "success": false,
  "message": "Error message",
  "data": null,
  "error": null
}
```

## API endpoints

Base URL: `http://localhost:3000/api`

Auth:

- `POST /auth/register` body `{ "email": "...", "password": "...", "name": "..." }`
- `POST /auth/login` body `{ "email": "...", "password": "..." }`
- `GET /auth/me` header `Authorization: Bearer <token>`
- `PATCH /auth/profile` body `{ "name": "..." }`
- `PATCH /auth/password` body `{ "currentPassword": "...", "newPassword": "..." }`

Groups:

- `GET /groups`
- `POST /groups` body `{ "name": "...", "description": "", "memberIds": [] }`
- `GET /groups/:id`
- `PUT /groups/:id` body `{ "name": "...", "description": "" }`
- `DELETE /groups/:id`
- `POST /groups/:id/members/email` body `{ "email": "member@example.com" }`
- `POST /groups/:id/members` body `{ "userId": "..." }`
- `DELETE /groups/:id/members/:userId`

Tasks:

- `GET /tasks`
- `GET /tasks?search=abc&priority=high&isCompleted=false&groupId=...`
- `POST /tasks` body `{ "title": "...", "description": "", "deadline": "2026-05-15T12:00:00.000Z", "priority": "medium", "groupId": null }`
- `GET /tasks/:id`
- `PUT /tasks/:id` body cac field can cap nhat
- `PATCH /tasks/:id/toggle`
- `DELETE /tasks/:id`

Tat ca endpoint `groups` va `tasks` can Bearer token.
