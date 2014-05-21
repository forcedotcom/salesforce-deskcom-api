require 'spec_helper'

describe DeskApi::Default do
  context '#options' do
    it 'returns a hash with mostly nil values' do
      expect(DeskApi::Default.options).to eq({
        consumer_key: nil,
        consumer_secret: nil,
        token: nil,
        token_secret: nil,
        username: nil,
        password: nil,
        subdomain: nil,
        endpoint: nil,
        connection_options: {
          headers: {
            accept: 'application/json',
            user_agent: "desk.com Ruby Gem v#{DeskApi::VERSION}"
          },
          request: {
            open_timeout: 5,
            timeout: 10
          }
        }
      })
    end

    it 'returns a hash with environmental variables' do
      ENV['DESK_CONSUMER_KEY'] = 'CK'
      ENV['DESK_CONSUMER_SECRET'] = 'CS'
      ENV['DESK_TOKEN'] = 'TOK'
      ENV['DESK_TOKEN_SECRET'] = 'TOKS'
      ENV['DESK_USERNAME'] = 'UN'
      ENV['DESK_PASSWORD'] = 'PW'
      ENV['DESK_SUBDOMAIN'] = 'SD'
      ENV['DESK_ENDPOINT'] = 'EP'

      expect(DeskApi::Default.options).to eq({
        consumer_key: 'CK',
        consumer_secret: 'CS',
        token: 'TOK',
        token_secret: 'TOKS',
        username: 'UN',
        password: 'PW',
        subdomain: 'SD',
        endpoint: 'EP',
        connection_options: {
          headers: {
            accept: 'application/json',
            user_agent: "desk.com Ruby Gem v#{DeskApi::VERSION}"
          },
          request: {
            open_timeout: 5,
            timeout: 10
          }
        }
      })

      ENV['DESK_CONSUMER_KEY'] = nil
      ENV['DESK_CONSUMER_SECRET'] = nil
      ENV['DESK_TOKEN'] = nil
      ENV['DESK_TOKEN_SECRET'] = nil
      ENV['DESK_USERNAME'] = nil
      ENV['DESK_PASSWORD'] = nil
      ENV['DESK_SUBDOMAIN'] = nil
      ENV['DESK_ENDPOINT'] = nil
    end
  end
end
