import { INestApplication, ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { json, urlencoded } from 'express';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter.js';
import { ResponseInterceptor } from './common/interceptors/response.interceptor.js';

export function configureApp(app: INestApplication) {
  app.setGlobalPrefix('api/v1');
  app.enableCors({ origin: true, credentials: true });
  // Entries create the app with `bodyParser: false`; register parsers here with
  // a limit that accommodates base64 product/KYC images (default is 100 KB,
  // which rejected any item with a photo as 413).
  app.use(json({ limit: '6mb' }));
  app.use(urlencoded({ extended: true, limit: '6mb' }));
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalInterceptors(new ResponseInterceptor());

  const config = new DocumentBuilder()
    .setTitle('SwarnaLekh API')
    .setDescription('Multi-tenant jewellery shop management API')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);
}
