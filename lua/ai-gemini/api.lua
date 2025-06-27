-- lua/ai-gemini/api.lua

local M = {}
local opts = {}

function M.setup(plugin_opts)
    opts = plugin_opts
end

local function build_request_body(model_config, prompt, selected_text)
    local messages = {}
    table.insert(messages, { role = "system", content = opts.prompt })

    if selected_text and selected_text ~= "" then
        table.insert(messages, { role = "user", content = prompt .. "\n```\n" .. selected_text .. "\n```" })
    else
        table.insert(messages, { role = "user", content = prompt })
    end

    if model_config.api_type == "openai" then
        return vim.fn.json_encode({
            model = model_config.model,
            messages = messages,
            temperature = model_config.temperature,
            top_p = model_config.top_p,
            max_tokens = model_config.max_tokens,
            stream = true,
        })
    elseif model_config.api_type == "google_gemini" then
        local contents = {}
        for _, msg in ipairs(messages) do
            table.insert(contents, {
                role = msg.role == "user" and "user" or "model",
                parts = {{ text = msg.content }}
            })
        end
        return vim.fn.json_encode({
            contents = contents,
            generationConfig = {
                temperature = model_config.temperature,
                topP = model_config.top_p,
                maxOutputTokens = model_config.max_tokens,
            },
        })
    elseif model_config.api_type == "ollama" then
        return vim.fn.json_encode({
            model = model_config.model,
            messages = messages,
            options = {
                temperature = model_config.temperature,
                top_p = model_config.top_p,
                num_predict = model_config.max_tokens,
            },
            stream = true,
        })
    else
        vim.notify("AI-Gemini: Unsupported API type: " .. model_config.api_type, vim.log.levels.ERROR)
        return nil
    end
end

function M.send_chat_request(model_config, prompt, selected_text, callback)
    local api_key = model_config.fetch_key()
    if not api_key and model_config.api_type ~= "ollama" then
        vim.notify("AI-Gemini: API Key not available for " .. model_config.name .. ". Please set it in your lazy.nvim config.", vim.log.levels.ERROR)
        callback(false, "API Key missing.")
        return
    end

    local url = model_config.url
    local headers = { "Content-Type: application/json" }
    local authorization_header = ""

    if model_config.api_type == "openai" then
        authorization_header = "Authorization: Bearer " .. api_key
        table.insert(headers, authorization_header)
    elseif model_config.api_type == "google_gemini" then
        url = url .. "?key=" .. api_key
    end

    local body = build_request_body(model_config, prompt, selected_text)
    if not body then
        callback(false, "Failed to build request body.")
        return
    end

    local cmd_args = { "curl", "-N", "-X", "POST" }
    for _, h in ipairs(headers) do
        table.insert(cmd_args, "-H")
        table.insert(cmd_args, h)
    end
    table.insert(cmd_args, "-d")
    table.insert(cmd_args, body)
    table.insert(cmd_args, url)

    if opts.enable_trace then
        vim.notify("AI-Gemini: Sending request: " .. table.concat(cmd_args, " "), vim.log.levels.DEBUG)
    end

    local full_response_content = {}
    local current_chunk_buffer = ""

    local on_stdout = function(job_id, data, event)
        if event == "stdout" then
            for _, chunk_line in ipairs(data) do
                if model_config.api_type == "openai" or model_config.api_type == "ollama" then
                    if chunk_line:find("^data: ") then
                        local json_part = chunk_line:sub(7)
                        if json_part ~= "[DONE]" then
                            local status, decoded = pcall(vim.fn.json_decode, json_part)
                            if status and decoded and decoded.choices and decoded.choices[1] then
                                local delta = decoded.choices[1].delta
                                if delta and delta.content then
                                    local content = delta.content
                                    table.insert(full_response_content, content)
                                    if ui.is_chat_window_open() then
                                        ui.append_to_chat_window(content)
                                    end
                                end
                            end
                        end
                    elseif chunk_line == "" then
                    else
                        vim.notify("AI-Gemini (streaming): Unhandled chunk: " .. chunk_line, vim.log.levels.DEBUG)
                    end
                elseif model_config.api_type == "google_gemini" then
                    local status, decoded = pcall(vim.fn.json_decode, chunk_line)
                    if status and decoded and decoded.candidates and decoded.candidates[1] and decoded.candidates[1].content and decoded.candidates[1].content.parts and decoded.candidates[1].content.parts[1] and decoded.candidates[1].content.parts[1].text then
                        local content = decoded.candidates[1].content.parts[1].text
                        table.insert(full_response_content, content)
                        if ui.is_chat_window_open() then
                            ui.append_to_chat_window(content)
                        end
                    end
                else
                    table.insert(full_response_content, chunk_line)
                end
            end
        end
    end

    local on_stderr = function(job_id, data, event)
        if event == "stderr" then
            for _, line in ipairs(data) do
                vim.notify("AI-Gemini (curl error): " .. line, vim.log.levels.ERROR)
            end
        end
    end

    local on_exit = function(job_id, code, event)
        if code == 0 then
            callback(true, table.concat(full_response_content, ""))
        else
            callback(false, "Curl exited with code: " .. code)
        end
    end

    vim.fn.jobstart(cmd_args, {
        on_stdout = on_stdout,
        on_stderr = on_stderr,
        on_exit = on_exit,
        pty = false,
        detach = true,
    })
end

return M
