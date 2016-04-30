require "http/client"
require "json"
require "./gcm/*"

class GCM
  @api_key : String
  @config : Config
  BASE_URI = "https://gcm-http.googleapis.com/gcm"

  def initialize(@api_key)
    @config = Config.new
  end

  def initialize(@api_key, &block)
    @config = Config.new
    yield @config
  end

  # {
  #   "collapse_key": "score_update",
  #   "time_to_live": 108,
  #   "delay_while_idle": true,
  #   "registration_ids": ["4", "8", "15", "16", "23", "42"],
  #   "data" : {
  #     "score": "5x1",
  #     "time": "15:10"
  #   }
  # }
  # gcm = GCM.new("API_KEY")
  # gcm.send(["4sdsx", "8sdsd"], {data: {score: "5x1"}})

  # def send(registration_ids : Array(String), options : Options)
  def send(registration_ids : Array(String), options : Hash? = nil)
    json = String.build do |io|
      io.json_object do |obj|
        options.try &.each do |key, value|
          obj.field key, value
        end
        obj.field "registration_ids", registration_ids
      end
    end

    headers = HTTP::Headers{
      "Authorization" => "key=#{@api_key}",
      "Content-Type" => "application/json"
    }

    response = api_execute("POST", "/send", options.to_json, headers)
    build_response(response, registration_ids)
  end

  def api_execute(method : String, path : String, body : String, headers : HTTP::Headers) : HTTP::Client::Response
    HTTP::Client.exec(method, BASE_URI + path, body: body, headers: headers)
  end

  def build_response(http_response : HTTP::Client::Response, registration_ids : Array(String))
    response = Response.new(http_response.body, http_response.headers, http_response.status_code)

    case
    when response.status_code == 200
      response.response = "success"
      body = SendResponse.from_json(response.body_as_json)
      response.canonical_ids = build_canonical_ids(body, registration_ids) unless registration_ids.empty?
      response.not_registered_ids = build_not_registered_ids(body, registration_ids) unless registration_ids.empty?
    when response.status_code == 400
      response.response = "Only applies for JSON requests. Indicates that the request could not be parsed as JSON, or it contained invalid fields."
    when response.status_code == 401
      response.response = "There was an error authenticating the sender account."
    when response.status_code == 503
      response.response = "Server is temporarily unavailable."
    when (500..599).includes?(response.status_code)
      response.response = "There was an internal error in the GCM server while trying to process the request."
    end
    response
  end

  def build_canonical_ids(body : SendResponse, registration_ids : Array(String)) : Array(CanonicalID)
    canonical_ids = [] of CanonicalID

    if body.canonical_ids > 0
      body.results.each_with_index do |result, index|
        canonical_ids << CanonicalID.new(result.registration_id, registration_ids[index]) if has_canonical_id?(result)
      end
    end
    canonical_ids
  end

  def build_not_registered_ids(body : SendResponse, registration_id : Array(String))
    not_registered_ids = [] of String

    if body.failure > 0
      body.results.each_with_index do |result, index|
        not_registered_ids << registration_id[index] if is_not_registered?(result)
      end
    end
    not_registered_ids
  end

  def has_canonical_id?(result : Result)
    !result.registration_id.nil?
  end

  def is_not_registered?(result)
    result.error == "NotRegistered"
  end
end
