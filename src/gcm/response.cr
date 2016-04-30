class GCM
  class SendResponse
    JSON.mapping({
      failure: {type: Int64, default: 0_i64},
      canonical_ids: {type: Int64, default: 0_i64},
      results: {type: Array(Result), default: [] of Result}
    })
  end

  class Result
    JSON.mapping({
      registration_id: String,
      message_id: String,
      error: String
    })
  end

  class Response
    property body : String
    property headers : HTTP::Headers
    property status_code : Int32
    property response : String
    property canonical_ids : Array(CanonicalID)
    property not_registered_ids : Array(String)

    def initialize(body : String, headers : HTTP::Headers, status_code : Int)
      @body = body
      @headers = headers
      @status_code = status_code
      @response = ""
      @canonical_ids = [] of CanonicalID
      @not_registered_ids = [] of String
    end

    def ==(other : Response)
      self.body == other.body &&
      self.headers == other.headers &&
      self.status_code == other.status_code &&
      self.response == other.response &&
      self.canonical_ids == other.canonical_ids &&
      self.not_registered_ids == other.not_registered_ids
    end

    def body_as_json
      if self.body == ""
        "{}"
      else
        self.body
      end
    end
  end

  class CanonicalID
    property new_id : String
    property old_id : String

    def initialize(new_id : String, old_id : String)
      @new_id = new_id
      @old_id = old_id
    end
  end
end
