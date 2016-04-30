require "./spec_helper"

class WebMock::Stub
  @calls = 0
  @id = ""

  def initialize(@method : Symbol, uri)
    @uri = parse_uri(uri)

    # For to_return
    @status = 200
    @body = ""
    @headers = HTTP::Headers{"Content-length": "0"}
    @calls = 0
  end

  def exec
    @calls += 1
    HTTP::Client::Response.new(@status, body: @body, headers: @headers)
  end

  def calls
    @calls
  end
end

Spec2.describe GCM do
  let(:send_url) { "#{GCM::BASE_URI}/send" }

  before do
    WebMock.reset
  end

  describe "sending notification" do
    let(:api_key) { "AIzaSyB-1uEai2WiUapxCs2Q0GZYzPu7Udno5aA" }
    let(:registration_ids) { ["42"] }
    let(:valid_request_body) do
      { registration_ids: registration_ids }
    end

    let(:valid_request_headers) do
      HTTP::Headers{
        "Content-Type": "application/json",
        "Authorization": "key=#{api_key}"
      }
    end

    let(:stub_gcm_send_request) do
      WebMock.stub(:post, send_url).with(
        body: valid_request_body.to_json,
        headers: valid_request_headers
      ).to_return(
        # ref: http://developer.android.com/guide/google/gcm/gcm.html#success
        body: "{}",
        headers: HTTP::Headers.new,
        status: 200
      )
    end

    let(:stub_gcm_send_request_with_basic_auth) do
      uri = URI.parse(send_url)
      uri.user = "a"
      uri.password = "b"
      WebMock.stub(:post, uri.to_s).to_return(body: "{}", headers: HTTP::Headers.new, status: 200)
    end

    before do
      # stub_gcm_send_request
      # stub_gcm_send_request_with_basic_auth
    end

    it "should send notification using POST to GCM server" do
      stub_gcm_send_request # register this

      gcm = GCM.new(api_key)
      response = GCM::Response.new("{}", HTTP::Headers{"Content-length" => "2"}, 200)
      response.canonical_ids = [] of GCM::CanonicalID
      response.not_registered_ids = [] of String
      response.response = "success"
      expect(gcm.send(registration_ids, {} of String => JSON::Type)).to eq(response)
      expect(stub_gcm_send_request.calls).to eq(1)
    end

    it "should use basic authentication provided by options" do
      stub_gcm_send_request_with_basic_auth # registe this

      gcm = GCM.new(api_key) do |config|
        config.username = "a"
        config.password = "b"
      end

      response = GCM::Response.new("{}", HTTP::Headers{"Content-length" => "2"}, 200)
      response.canonical_ids = [] of GCM::CanonicalID
      response.not_registered_ids = [] of String
      response.response = "success"

      options = {
        "data": {
          "a": "b"
        } of String => JSON::Type
      } of String => JSON::Type
      expect(gcm.send(registration_ids, {} of String => JSON::Type)).to eq(response)
      expect(stub_gcm_send_request_with_basic_auth.calls).to eq(1)
    end

    describe "send notification with data" do
      let(:stub_with_data) do
        WebMock.stub(:post, send_url)
          .with(body: %({"data":{"score":"5x1","time":"15:10"},"registration_ids":["42"]}),
                headers: valid_request_headers)
          .to_return(status: 200, body: "", headers: HTTP::Headers.new)
      end

      it "should send the data in a post request to gcm" do
        stub_with_data # register this

        gcm = GCM.new(api_key)
        options = {
          "data": {
            "score": "5x1",
            "time": "15:10"
          } of String => JSON::Type
        } of String => JSON::Type

        gcm.send(registration_ids, options)

        expect(stub_with_data.calls).to eq(1)
      end
    end

    describe "when send_notification responds with failure" do
      subject { GCM.new(api_key) }

      describe "on failure code 400" do
        before do
          WebMock.stub(:post, send_url).with(
            body: valid_request_body.to_json,
            headers: valid_request_headers
          ).to_return(
            # ref: http://developer.android.com/guide/google/gcm/gcm.html#success
            body: "{}",
            headers: HTTP::Headers.new,
            status: 400
          )
        end

        it "should not send notification due to 400" do
          response = GCM::Response.new("{}", HTTP::Headers{"Content-length" => "2"}, 400)
          response.response = "Only applies for JSON requests. Indicates that the request could not be parsed as JSON, or it contained invalid fields."
          expect(subject.send(registration_ids)).to eq(response)
        end
      end

      describe "on failure code 401" do
        before do
          WebMock.stub(:post, send_url).with(
            body: valid_request_body.to_json,
            headers: valid_request_headers
          ).to_return(
            # ref: http://developer.android.com/guide/google/gcm/gcm.html#success
            body: "{}",
            headers: HTTP::Headers.new,
            status: 401
          )
        end

        it "should not send notification due to 401" do
          response = GCM::Response.new("{}", HTTP::Headers{"Content-length" => "2"}, 401)
          response.response = "There was an error authenticating the sender account."
          expect(subject.send(registration_ids)).to eq(response)
        end
      end

      describe "on failure code 503" do
        before do
          WebMock.stub(:post, send_url).with(
            body: valid_request_body.to_json,
            headers: valid_request_headers
          ).to_return(
            # ref: http://developer.android.com/guide/google/gcm/gcm.html#success
            body: "{}",
            headers: HTTP::Headers.new,
            status: 503
          )
        end

        it "should not send notification due to 503" do
          response = GCM::Response.new("{}", HTTP::Headers{"Content-length" => "2"}, 503)
          response.response = "Server is temporarily unavailable."
          expect(subject.send(registration_ids)).to eq(response)
        end
      end

      describe "on failure code 5xx" do
        before do
          WebMock.stub(:post, send_url).with(
            body: valid_request_body.to_json,
            headers: valid_request_headers
          ).to_return(
            # ref: http://developer.android.com/guide/google/gcm/gcm.html#success
            body: %({"body-key" => "Body value"}),
            headers: HTTP::Headers{ "header-key" => "Header value" },
            status: 599
          )
        end

        it "should not send notification due to 599" do
          response = GCM::Response.new(%({"body-key" => "Body value"}), HTTP::Headers{"Content-length" => "28", "header-key" => "Header value"}, 599)
          response.response = "There was an internal error in the GCM server while trying to process the request."
          expect(subject.send(registration_ids)).to eq(response)
        end
      end
    end
  end
end
