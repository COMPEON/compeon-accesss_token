# frozen_string_literal: true

require 'test_helper'

class Compeon::Token::EncoderTest < Minitest::Test
  PRIVATE_KEY = OpenSSL::PKey::RSA.new(512)

  class TestToken
    include Compeon::Token::Base.attributes(attribute: :attr)

    KIND = 'test'
  end

  def test_with_a_valid_token
    token = TestToken.new(attribute: '1 Attribut')
    token.claims[:exp] = Time.now.to_i + 3600

    encoded_token = Compeon::Token::Encoder.new(
      private_key: PRIVATE_KEY,
      token: token
    ).encode

    assert_equal(String, encoded_token.class)

    decoded_token = JWT.decode(
      encoded_token,
      PRIVATE_KEY.public_key,
      true,
      algorithm: 'RS256'
    )[0]

    assert_equal('1 Attribut', decoded_token['attr'])
    assert_equal('test', decoded_token['knd'])
  end

  def test_with_additional_claims
    expires_at = Time.now.to_i + 3600
    token = TestToken.new(attribute: '1 Attribut')
    token.claims[:exp] = expires_at
    token.claims[:iss] = 'compeon'
    token.claims[:sub] = 'auth'

    encoded_token = Compeon::Token::Encoder.new(
      private_key: PRIVATE_KEY,
      token: token
    ).encode

    assert_equal(String, encoded_token.class)

    decoded_token = JWT.decode(
      encoded_token,
      PRIVATE_KEY.public_key,
      true,
      algorithm: 'RS256'
    )[0]

    assert_equal(expires_at, decoded_token['exp'])
    assert_equal('compeon', decoded_token['iss'])
    assert_equal('auth', decoded_token['sub'])
  end

  def test_with_an_expiry_time_in_the_past
    token = TestToken.new(attribute: '1 Attribut')
    token.claims[:exp] = Time.now.to_i - 1

    assert_raises do
      Compeon::Token::Encoder.new(
        private_key: PRIVATE_KEY,
        token: token
      ).encode
    end
  end

  def test_without_an_exp_claim
    token = TestToken.new(attribute: '1 Attribut')

    assert_raises do
      Compeon::Token::Encoder.new(
        private_key: PRIVATE_KEY,
        token: token
      ).encode
    end
  end

  def test_with_a_missing_attribute
    token = TestToken.new(attribute: nil)
    token.claims[:exp] = Time.now.to_i + 3600

    assert_raises do
      Compeon::Token::Encoder.new(
        private_key: PRIVATE_KEY,
        token: token
      ).encode
    end
  end

  def test_with_a_missing_private_key
    token = TestToken.new(attribute: '1 Attribut')
    token.claims[:exp] = Time.now.to_i + 3600

    assert_raises do
      Compeon::Token::Encoder.new(
        private_key: nil,
        token: token
      ).encode
    end
  end
end
