require "./spec_helper"

class WebMock::Stub
  @calls = 0

  def initialize(@method : Symbol, uri)
    @uri = parse_uri(uri)

    # For to_return
    @status = 200
    @body = ""
    @headers = HTTP::Headers{"Content-length": "0"}
    @calls_count = 0
  end
end

Spec2.describe GCM do
  let(:send_url) { "#{GCM::BASE_URI}/send" }

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
      stub_gcm_send_request
      stub_gcm_send_request_with_basic_auth
    end

    it "should send notification using POST to GCM server" do
      gcm = GCM.new(api_key)
      response = GCM::Response.new("{}", HTTP::Headers{"Content-length" => "2"}, 200)
      response.canonical_ids = [] of GCM::CanonicalID
      response.not_registered_ids = [] of String
      response.response = "success"
      options = {
        "data": {
          "a": "b"
        } of String => JSON::Type,
        "foo": ["a", "b"] of JSON::Type
      } of String => JSON::Type
      expect(gcm.send(registration_ids, options)).to eq(response)
      # stub_gcm_send_request.should have_been_made.times(1)
    end

    it "should use basic authentication provided by options" do
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
      expect(gcm.send(registration_ids, options)).to eq(response)
      # stub_gcm_send_request_with_basic_auth.should have_been_made.times(1)
    end

    describe "send notification with data" do
      let!(:stub_with_data) do
        WebMock.stub(:post, send_url)
          .with(body: %({"registration_ids":["42"],"data":{"score":"5x1","time":"15:10"}}),
                headers: valid_request_headers)
          .to_return(status: 200, body: "", headers: HTTP::Headers.new)
      end

      it "should send the data in a post request to gcm" do
        gcm = GCM.new(api_key)
        options = {
          "data": {
            "score": "5x1",
            "time": "15:10"
          } of String => JSON::Type
        } of String => JSON::Type
        gcm.send(registration_ids, options)
        # stub_with_data.should have_been_requested
      end
    end
  end
end
