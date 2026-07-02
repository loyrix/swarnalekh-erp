import { createHmac } from 'node:crypto';
import { signAuthToken } from './auth.token';

const decode = (part: string) =>
  JSON.parse(Buffer.from(part, 'base64url').toString('utf8'));

describe('signAuthToken', () => {
  const secret = 'unit-test-secret';

  it('produces a verifiable HS256 JWT with the expected claims', () => {
    const { token, expiresAt } = signAuthToken(
      { sub: 'u1', email: 'a@b.com', role: 'owner', tenantId: 't1' },
      secret,
      3600,
      1000,
    );

    const [header, payload, signature] = token.split('.');
    expect(token.split('.')).toHaveLength(3);
    expect(decode(header)).toEqual({ alg: 'HS256', typ: 'JWT' });
    expect(decode(payload)).toMatchObject({
      sub: 'u1',
      email: 'a@b.com',
      role: 'owner',
      tenantId: 't1',
      iss: 'swarnalekh',
      iat: 1000,
      exp: 4600,
    });
    expect(expiresAt).toBe(4600);

    const expected = createHmac('sha256', secret)
      .update(`${header}.${payload}`)
      .digest('base64url');
    expect(signature).toBe(expected);
  });

  it('omits the email claim when not provided', () => {
    const { token } = signAuthToken(
      { sub: 'u1', role: 'staff', tenantId: 't1' },
      secret,
      60,
      0,
    );
    expect('email' in decode(token.split('.')[1])).toBe(false);
  });

  it('signs differently under different secrets', () => {
    const claims = { sub: 'u', role: 'r', tenantId: 't' };
    const a = signAuthToken(claims, 'x', 60, 0).token.split('.')[2];
    const b = signAuthToken(claims, 'y', 60, 0).token.split('.')[2];
    expect(a).not.toBe(b);
  });
});
