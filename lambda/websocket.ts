import express, { Request, Response, NextFunction } from 'express';
import serverless from 'serverless-http';
import { ApiGatewayManagementApiClient, PostToConnectionCommand } from '@aws-sdk/client-apigatewaymanagementapi';

interface WebSocketRequestContext {
  connectionId: string;
  domainName: string;
  stage: string;
}

interface WebSocketMessage {
  message: string;
}

interface WebSocketRequest extends Request {
  requestContext: WebSocketRequestContext;
  body: WebSocketMessage;
}

const app = express();
app.use(express.json());

const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE || '';
const STAGE = process.env.STAGE || 'dev';

const createApiGatewayClient = (endpoint: string) => {
  return new ApiGatewayManagementApiClient({
    endpoint: `https://${endpoint}/${STAGE}`,
  });
};

// WebSocket $connect route
app.post('/$connect', async (req: Request, res: Response) => {
  const wsReq = req as WebSocketRequest;
  const connectionId = wsReq.requestContext.connectionId;
  
  // Here you would typically save the connectionId to DynamoDB
  console.log(`Client connected with connectionId: ${connectionId}`);

  res.status(200).json({ message: 'Connected' });
});

// WebSocket $disconnect route
app.post('/$disconnect', async (req: Request, res: Response) => {
  const wsReq = req as WebSocketRequest;
  const connectionId = wsReq.requestContext.connectionId;
  
  // Here you would typically remove the connectionId from DynamoDB
  console.log(`Client disconnected with connectionId: ${connectionId}`);

  res.status(200).json({ message: 'Disconnected' });
});

// WebSocket message route
app.post('/message', async (req: Request, res: Response) => {
  const wsReq = req as WebSocketRequest;
  const { connectionId, domainName, stage } = wsReq.requestContext;
  const body = wsReq.body;

  try {
    const client = createApiGatewayClient(`${domainName}/${stage}`);
    
    // Here you would typically get all connectionIds from DynamoDB and broadcast
    // For now, we'll just echo back to the sender
    await client.send(
      new PostToConnectionCommand({
        ConnectionId: connectionId,
        Data: JSON.stringify({
          message: `Echo: ${body.message}`,
          timestamp: new Date().toISOString(),
        }),
      })
    );

    res.status(200).json({ message: 'Message sent' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ message: 'Failed to send message' });
  }
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err);
  res.status(500).json({ message: 'Internal server error' });
});

// Create serverless handler
const handler = serverless(app);

// Export the handler for each route
export const connect = handler;
export const disconnect = handler;
export const message = handler; 