local http = require "resty.http"

local CustomAuthHandler = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}

function CustomAuthHandler:access(config)

  -- Get Authorization header from incoming request
  local authorization = kong.request.get_header("Authorization")

  if not authorization then
    return kong.response.exit(401, {
      message = "Authorization header is required"
    })
  end

  -- Create HTTP client
  local httpc = http.new()

  httpc:set_timeouts(
    10000,
    10000,
    10000
  )

  -- Call auth service
  local res, err = httpc:request_uri(
    config.auth_service_url,
    {
      method = "GET",

      headers = {
        ["Authorization"] = authorization
      }
    }
  )

  -- Auth service unavailable
  if not res then

    kong.log.err("AUTH REQUEST ERROR: ", err)

    return kong.response.exit(
      503,
      {
        message = "Authentication service unavailable"
      }
    )
  end


  kong.log.debug("AUTH STATUS: ", tostring(res.status))
  kong.log.debug("AUTH BODY: ", tostring(res.body))

  -- Token invalid
  if res.status ~= 200 then
    kong.log.err(
        "AUTH FAILED. STATUS=",
        tostring(res.status),
        " BODY=",
        tostring(res.body)
    )

    return kong.response.exit(
      401,
      {
        message = "Unauthorized"
      }
    )
  end

  -- Auth service should return user ID
  local user_id = res.body

  if not user_id or user_id == "" then

    kong.log.err(
      "Auth service returned empty user ID"
    )

    return kong.response.exit(
      401,
      {
        message = "Invalid authentication response"
      }
    )
  end

  -- Add user ID to request sent to upstream service
  kong.service.request.set_header(
    "X-User-ID",
    user_id
  )

end

return CustomAuthHandler