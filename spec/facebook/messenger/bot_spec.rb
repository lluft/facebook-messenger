require 'spec_helper'

describe Facebook::Messenger::Bot do
  let(:messages_url) do
    Facebook::Messenger::Subscriptions.base_uri + '/messages'
  end

  let(:access_token) { '<access token>' }

  subject { Facebook::Messenger::Bot.new(access_token) }

  describe '.message' do
    let(:payload) do
      {
        recipient: {
          id: '123'
        },
        message: {
          text: 'Hello, human!'
        }
      }
    end

    def stub_request_to_return(hash)
      stub_request(:post, messages_url)
        .with(
          query: { access_token: access_token },
          body: payload
        )
        .to_return(
          body: JSON.dump(hash),
          status: 200,
          headers: default_graph_api_response_headers
        )
    end

    context 'when all is well' do
      let(:message_id) { 'mid.1456970487936:c34767dfe57ee6e339' }

      before do
        stub_request_to_return(
          recipient_id: '1008372609250235',
          message_id: message_id
        )
      end

      it 'sends a message' do
        expect(subject.message(payload)).to eq(message_id)
      end
    end

    context 'when the recipient could not be found' do
      before do
        stub_request_to_return(
          error: {
            message: 'Invalid parameter',
            type: 'FacebookApiException',
            code: 100,
            error_data: 'No matching user found.',
            fbtrace_id: 'D2kxCybrKVw'
          }
        )
      end

      it 'sends a message' do
        expect { subject.message(payload) }.to raise_error(
          Facebook::Messenger::Bot::RecipientNotFound,
          'No matching user found.'
        )
      end
    end

    context 'when the application does not have permission to use the API' do
      before do
        stub_request_to_return(
          error: {
            message: 'Invalid parameter',
            type: 'FacebookApiException',
            code: 10,
            error_data: 'Application does not have permission ' \
                        'to use the Send API.',
            fbtrace_id: 'D2kxCybrKVw'
          }
        )
      end

      it 'sends a message' do
        expect { subject.message(payload) }.to raise_error(
          Facebook::Messenger::Bot::PermissionDenied,
          'Application does not have permission to use the Send API.'
        )
      end
    end

    context 'when Facebook had an internal server error' do
      before do
        stub_request_to_return(
          error: {
            message: 'Invalid parameter',
            type: 'FacebookApiException',
            code: 2,
            error_data: 'Send message failure. Internal server error.',
            fbtrace_id: 'D2kxCybrKVw'
          }
        )
      end

      it 'sends a message' do
        expect { subject.message(payload) }.to raise_error(
          Facebook::Messenger::Bot::InternalError,
          'Send message failure. Internal server error.'
        )
      end
    end
  end
end
