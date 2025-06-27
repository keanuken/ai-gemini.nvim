-- lua/ai-gemini/ui.lua

local M = {}
local opts = {}
local nui = require("nui.popup")
local uv = vim.loop
local chat_popup = nil
local spinner_timer = nil
local spinner_frame = 1

function M.setup(plugin_opts)
    opts = plugin_opts
end

function M.show_spinner()
    if spinner_timer then
        uv.timer_stop(spinner_timer)
    end

    spinner_timer = uv.new_timer()
    uv.timer_start(spinner_timer, 0, 150, vim.schedule_wrap(function()
        spinner_frame = (spinner_frame % #opts.spinner.text) + 1
        local spinner_char = opts.spinner.text[spinner_frame]
        vim.api.nvim_echo({{spinner_char, opts.spinner.hl}}, true, {})
    end))
end

function M.hide_spinner()
    if spinner_timer then
        uv.timer_stop(spinner_timer)
        spinner_timer = nil
    end
    vim.api.nvim_echo({{"", "Normal"}}, false, {})
end

function M.open_chat_window()
    if chat_popup then
        chat_popup:open()
        return
    end

    chat_popup = nui.new(
        opts.chat_window,
        {
            buf_options = {
                modifiable = false,
                readonly = true,
            },
            win_options = opts.chat_window.win_options,
        }
    )

    chat_popup:map("n", "q", function() chat_popup:close() end, { noremap = true, silent = true })
    chat_popup:map("n", "<esc>", function() chat_popup:close() end, { noremap = true, silent = true })

    chat_popup:open()

    local buf_id = chat_popup.bufnr
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {
        opts.prefix.assistant.text .. "Hello! How can I help you today?",
        "",
        opts.prefix.user.text .. " "
    })
    vim.api.nvim_buf_set_option(buf_id, 'modifiable', true)
    vim.api.nvim_buf_set_option(buf_id, 'readonly', false)

    vim.api.nvim_win_set_cursor(chat_popup.winid, {vim.api.nvim_buf_line_count(buf_id), 3})

    vim.api.nvim_buf_set_keymap(buf_id, 'i', '<CR>',
        [[<cmd>lua require('ai-gemini.ui').send_chat_input_and_process()<CR>]],
        { noremap = true, silent = true }
    )
end

function M.close_chat_window()
    if chat_popup then
        chat_popup:close()
        chat_popup = nil
    end
end

function M.is_chat_window_open()
    return chat_popup ~= nil and chat_popup.winid ~= nil and vim.api.nvim_win_is_valid(chat_popup.winid)
end

function M.append_to_chat_window(content)
    if M.is_chat_window_open() then
        local bufnr = chat_popup.bufnr
        local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local last_line_idx = #current_lines

        if current_lines[last_line_idx] and current_lines[last_line_idx]:find("^" .. opts.prefix.user.text) then
            vim.api.nvim_buf_set_lines(bufnr, last_line_idx -1, last_line_idx, false, {current_lines[last_line_idx-1], content})
        else
            vim.api.nvim_buf_set_lines(bufnr, last_line_idx, last_line_idx, false, {content})
        end

        vim.api.nvim_win_set_cursor(chat_popup.winid, {vim.api.nvim_buf_line_count(bufnr), 0})
        vim.cmd("normal! G")
    end
end

function M.send_chat_input_and_process()
    if not M.is_chat_window_open() then return end

    local bufnr = chat_popup.bufnr
    local last_line_idx = vim.api.nvim_buf_line_count(bufnr) - 1
    local input_line = vim.api.nvim_buf_get_lines(bufnr, last_line_idx, last_line_idx + 1, false)[1]

    local user_text = input_line:gsub("^" .. opts.prefix.user.text .. "%s*", "")

    if user_text == "" then
        return
    end

    vim.api.nvim_buf_set_lines(bufnr, last_line_idx, last_line_idx + 1, false, {
        opts.prefix.user.text .. user_text,
        "",
        opts.prefix.assistant.text .. "Thinking...",
    })

    vim.api.nvim_win_set_cursor(chat_popup.winid, {vim.api.nvim_buf_line_count(bufnr) - 1, #opts.prefix.assistant.text + 10})

    require("ai-gemini").handle_ai_request(user_text, nil, function(response_content)
        local thinking_line_idx = vim.api.nvim_buf_line_count(bufnr) - 1
        vim.api.nvim_buf_set_lines(bufnr, thinking_line_idx, thinking_line_idx + 1, false, {
            opts.prefix.assistant.text .. response_content,
            "",
            opts.prefix.user.text .. " "
        })
        vim.api.nvim_win_set_cursor(chat_popup.winid, {vim.api.nvim_buf_line_count(bufnr), #opts.prefix.user.text + 1})
    end)
end

return M

