# Tasky App - Task Management Application

A simple RESTful API for managing tasks, built with Node.js, Express, and MongoDB.

## Features

- Create, read, update, and delete tasks
- Mark tasks as complete/incomplete
- Set task priorities (low, medium, high)
- Set due dates for tasks
- Health check endpoint

## API Endpoints

- `GET /health` - Health check
- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/:id` - Get a specific task
- `POST /api/tasks` - Create a new task
- `PUT /api/tasks/:id` - Update a task
- `DELETE /api/tasks/:id` - Delete a task
- `GET /api/tasks/status/:completed` - Get tasks by completion status

## Environment Variables

- `MONGODB_URI` - MongoDB connection string (default: mongodb://localhost:27017/tasky)
- `PORT` - Server port (default: 3000)

## Running Locally

```bash
npm install
npm start
```

## Running with Docker

```bash
docker build -t tasky-app .
docker run -p 3000:3000 -e MONGODB_URI=mongodb://your-mongo-host:27017/tasky tasky-app
```

## Task Object Schema

```json
{
  "title": "Task title",
  "description": "Task description",
  "completed": false,
  "priority": "medium",
  "dueDate": "2024-12-31T00:00:00.000Z",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```
