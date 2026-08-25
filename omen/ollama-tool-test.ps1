function Test-OllamaTools([string]$model) {
  $bodyObj = @{
    model = $model
    stream = $false
    options = @{ temperature = 0 }
    messages = @(@{ role = "user"; content = "Call get_weather for Preston Idaho. Do not answer in prose." })
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
  }
  $body = $bodyObj | ConvertTo-Json -Depth 12
  $res = Invoke-RestMethod -Uri http://127.0.0.1:11434/api/chat -Method POST -Body $body -ContentType "application/json"
  $calls = @($res.message.tool_calls)
  Write-Host "==== $model ===="
  Write-Host "content: $($res.message.content)"
  Write-Host "tool_calls count: $($calls.Count)"
  $res.message | ConvertTo-Json -Depth 8
  if ($calls.Count -gt 0 -and $calls[0]) { Write-Host "PASS structured tool_calls" }
  else { Write-Host "FAIL no tool_calls — model printed text instead" }
}

Test-OllamaTools "llama3.1:8b"
# Only if llama fails:
# Test-OllamaTools "qwen2.5:14b"
