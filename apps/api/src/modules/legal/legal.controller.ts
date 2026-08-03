import { Controller, Get, Res } from '@nestjs/common';
import { ApiExcludeEndpoint, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { Public } from '../../common/decorators/public.decorator.js';
import { PRIVACY_POLICY_HTML } from './privacy-policy.html.js';

@ApiTags('Legal')
@Controller()
export class LegalController {
  // Served as raw HTML, so the response bypasses the global ResponseInterceptor
  // envelope by writing to the express response directly. The route is excluded
  // from the api/v1 global prefix in bootstrap.ts so the public URL stays clean
  // enough to paste into Google Play Console.
  @Get('privacy-policy')
  @Public()
  @ApiExcludeEndpoint()
  getPrivacyPolicy(@Res() res: Response) {
    res
      .type('html')
      .set('Cache-Control', 'public, max-age=3600')
      .send(PRIVACY_POLICY_HTML);
  }
}
