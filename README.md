# WebSocket Chat with AWS Lambda and Next.js

A real-time chat application using WebSocket API Gateway, Lambda, and Next.js.

## Prerequisites

- Node.js 18 or later
- AWS CLI configured with appropriate credentials
- Terraform

## Setup

1. Install dependencies:
```bash
npm install
```

2. Initialize Terraform:
```bash
terraform init
```

3. Deploy the infrastructure:
```bash
terraform apply
```

4. Create a `.env.local` file in the root directory with the WebSocket URL from Terraform output:
```bash
echo "NEXT_PUBLIC_WEBSOCKET_URL=$(terraform output -raw websocket_url)" > .env.local
```

5. Start the frontend:
```bash
npm run dev
```

## Development

- Frontend: The Next.js application runs on `http://localhost:3000`
- Backend: The WebSocket API is deployed on AWS

## Architecture

- Frontend: Next.js application with WebSocket client
- Backend: AWS Lambda functions handling WebSocket connections
- Database: DynamoDB for storing active connections
- API: API Gateway WebSocket API
- Infrastructure: Managed with Terraform

## Features

- Real-time bidirectional communication
- Automatic reconnection on connection loss
- Message broadcasting (echo in the current implementation)
- Connection state management

## Infrastructure Management

- To update infrastructure: `terraform apply`
- To destroy infrastructure: `terraform destroy`
- To view outputs: `terraform output`
- To format code: `terraform fmt` # react-socket-terraform-nodejs-lambda
