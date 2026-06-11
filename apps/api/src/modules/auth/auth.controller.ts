import { Controller, Get, Post, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * After Supabase login/signup on Flutter side, call this endpoint
   * with the authenticated JWT to get the app-level user profile
   * and tenant context.
   */
  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Resolve authenticated user',
    description:
      'Get the authenticated app user profile and tenant context from a Supabase JWT',
  })
  async getMe(@Req() req: any) {
    return req.appUser ?? this.authService.resolveUser(req.user);
  }

  @Post('me')
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Resolve authenticated user (legacy POST)',
    description:
      'Backward-compatible POST alias for resolving the authenticated app user profile',
  })
  async postMe(@Req() req: any) {
    return req.appUser ?? this.authService.resolveUser(req.user);
  }

  @Get('health')
  @Public()
  @ApiOperation({ summary: 'Auth module health check' })
  authHealth() {
    return { status: 'ok', module: 'auth' };
  }
}
