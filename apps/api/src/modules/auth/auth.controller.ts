import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto, RegisterDto } from './auth.dto';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Public()
  @ApiOperation({
    summary: 'Register a new shop',
    description:
      'Creates the tenant + owner user with a password and returns a session token.',
  })
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @Public()
  @ApiOperation({
    summary: 'Email + password login',
    description: 'Returns a first-party session token for the app user.',
  })
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Resolve authenticated user',
    description:
      'Get the authenticated app user profile and tenant context from a bearer JWT',
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
