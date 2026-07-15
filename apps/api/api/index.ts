import express from 'express';
import type { Request, Response } from 'express';
import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/bootstrap.js';

const server = express();
let isReady = false;

async function bootstrap() {
  if (!isReady) {
    const app = await NestFactory.create(
      AppModule,
      new ExpressAdapter(server),
      {
        // Body parsers are registered in configureApp with a raised limit.
        bodyParser: false,
      },
    );
    configureApp(app);
    await app.init();
    isReady = true;
  }

  return server;
}

export default async function handler(req: Request, res: Response) {
  const app = await bootstrap();
  return app(req, res);
}
