$body = @{
  model = "llama3.1:8b"
  stream = $false
  messages = @(@{ role = "user"; content = "What is the weather in Preston Idaho? Use the get_weather tool." })
  tools = @(@{
    type = "function"
    function = @{
      name = "get_weather"
      description = "Get weather for a city"
      parameters = @{
        type = "object"
        properties = @{ city = @{ type = "string" } }
        required = @("city")
      }
    }
  })
} | ConvertTo-Json -Depth 12

$res = Invoke-RestMethod -Uri http://127.0.0.1:11434/api/chat -Method POST -Body $body -ContentType "application/json"
$res.message | ConvertTo-Json -Depth 8

Write-Host "PASS = message.tool_calls is a non-empty array"
Write-Host "FAIL = only message.content with JSON/XML text and no tool_calls"
Write-Host "Repeat with model = qwen2.5:14b if llama fails. Do not pull a new model until this test is done."
