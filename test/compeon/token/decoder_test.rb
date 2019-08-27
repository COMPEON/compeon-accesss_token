# frozen_string_literal: true

require 'test_helper'

class Compeon::Token::DecoderTest < Minitest::Test
  PRIVATE_KEY = OpenSSL::PKey::RSA.new(512)

  class TestToken < Compeon::Token::Base
    class << self
      def attributes_mapping
        { attribute: :attr }.freeze
      end

      def kind
        'test'
      end
    end

    attr_accessor :attribute

    def initialize(attribute:)
      @attribute = attribute
    end
  end

  def test_with_a_valid_token
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test' }, PRIVATE_KEY, 'RS256')

    decoded_token = Compeon::Token::Decoder.new(
      encoded_token: encoded_token,
      public_key: PRIVATE_KEY.public_key,
      token_klass: TestToken
    ).decode

    assert_equal(TestToken, decoded_token.class)
    assert_equal('Ein Attribut', decoded_token.attribute)
  end

  def test_with_additional_claims
    expires_at = Time.now.to_i + 3600
    encoded_token = JWT.encode(
      {
        attr: 'Ein Attribut',
        knd: 'test',
        exp: expires_at,
        iss: 'compeon',
        sub: 'auth'
      },
      PRIVATE_KEY,
      'RS256'
    )

    decoded_token = Compeon::Token::Decoder.new(
      encoded_token: encoded_token,
      public_key: PRIVATE_KEY.public_key,
      token_klass: TestToken
    ).decode

    assert_equal(TestToken, decoded_token.class)
    assert_equal('Ein Attribut', decoded_token.attribute)
    assert_equal(expires_at, decoded_token.claims[:exp])
    assert_equal('compeon', decoded_token.claims[:iss])
    assert_equal('auth', decoded_token.claims[:sub])
  end

  def test_with_a_token_of_wrong_kind
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'not_test' }, PRIVATE_KEY, 'RS256')

    assert_raises Compeon::Token::DecodeError do
      Compeon::Token::Decoder.new(
        encoded_token: encoded_token,
        public_key: PRIVATE_KEY.public_key,
        token_klass: TestToken
      ).decode
    end
  end

  def test_with_an_expired_token
    encoded_token = JWT.encode({ attr: 'Ein Attribut', exp: 0, knd: 'test' }, PRIVATE_KEY, 'RS256')

    assert_raises Compeon::Token::DecodeError do
      Compeon::Token::Decoder.new(
        encoded_token: encoded_token,
        public_key: PRIVATE_KEY.public_key,
        token_klass: TestToken
      ).decode
    end
  end

  def test_with_a_valid_sub_claim
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test', sub: 'compeon' }, PRIVATE_KEY, 'RS256')

    Compeon::Token::Decoder.new(
      claim_verifications: { sub: 'compeon' },
      encoded_token: encoded_token,
      public_key: PRIVATE_KEY.public_key,
      token_klass: TestToken
    ).decode
  end

  def test_with_an_invalid_sub_claim
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test', sub: 'compeon' }, PRIVATE_KEY, 'RS256')

    assert_raises do
      Compeon::Token::Decoder.new(
        claim_verifications: { sub: 'not compeon' },
        encoded_token: encoded_token,
        public_key: PRIVATE_KEY.public_key,
        token_klass: TestToken
      ).decode
    end
  end

  def test_with_a_valid_iss_claim
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test', iss: 'compeon' }, PRIVATE_KEY, 'RS256')

    Compeon::Token::Decoder.new(
      claim_verifications: { iss: 'compeon' },
      encoded_token: encoded_token,
      public_key: PRIVATE_KEY.public_key,
      token_klass: TestToken
    ).decode
  end

  def test_with_an_invalid_iss_claim
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test', iss: 'compeon' }, PRIVATE_KEY, 'RS256')

    assert_raises do
      Compeon::Token::Decoder.new(
        claim_verifications: { iss: 'not compeon' },
        encoded_token: encoded_token,
        public_key: PRIVATE_KEY.public_key,
        token_klass: TestToken
      ).decode
    end
  end

  def test_with_a_valid_aud_claim
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test', aud: 'zuhörer' }, PRIVATE_KEY, 'RS256')

    Compeon::Token::Decoder.new(
      claim_verifications: { aud: 'zuhörer' },
      encoded_token: encoded_token,
      public_key: PRIVATE_KEY.public_key,
      token_klass: TestToken
    ).decode
  end

  def test_with_an_invalid_aud_claim
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test', aud: 'zuhörer' }, PRIVATE_KEY, 'RS256')

    assert_raises do
      Compeon::Token::Decoder.new(
        claim_verifications: { aud: 'not zuhörer' },
        encoded_token: encoded_token,
        public_key: PRIVATE_KEY.public_key,
        token_klass: TestToken
      ).decode
    end
  end

  def test_with_a_valid_iat_claim
    current_time = Time.now.to_i
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test', iat: current_time }, PRIVATE_KEY, 'RS256')

    Compeon::Token::Decoder.new(
      claim_verifications: { iat: current_time },
      encoded_token: encoded_token,
      public_key: PRIVATE_KEY.public_key,
      token_klass: TestToken
    ).decode
  end

  def test_with_an_invalid_iat_claim
    encoded_token = JWT.encode({ attr: 'Ein Attribut', knd: 'test', iat: 'no time' }, PRIVATE_KEY, 'RS256')

    assert_raises do
      Compeon::Token::Decoder.new(
        claim_verifications: { iat: true },
        encoded_token: encoded_token,
        public_key: PRIVATE_KEY.public_key,
        token_klass: TestToken
      ).decode
    end
  end
end
