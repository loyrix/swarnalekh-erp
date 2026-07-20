import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let errors: any = undefined;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();

      if (typeof res === 'string') {
        message = res;
      } else if (typeof res === 'object') {
        const resObj = res as any;
        message = resObj.message || exception.message;
        errors = resObj.errors;

        // class-validator returns message as array
        if (Array.isArray(resObj.message)) {
          message = 'Validation failed';
          errors = resObj.message;
        }
      }
    } else if (exception instanceof Error) {
      message = exception.message;
    }

    // Every failed request gets exactly one log line carrying the method, path
    // and reason — a 4xx that logs nothing is invisible in production. The
    // validation details are inlined so "Validation failed" is never the whole
    // story (e.g. which property was rejected).
    const detail = Array.isArray(errors) ? ` — ${errors.join('; ')}` : '';
    const line = `${request.method} ${request.url} ${status}: ${message}${detail}`;
    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(
        line,
        exception instanceof Error ? exception.stack : undefined,
      );
    } else {
      this.logger.warn(line);
    }

    response.status(status).json({
      success: false,
      statusCode: status,
      message,
      errors,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
