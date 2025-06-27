-- plugin/ai-gemini.lua

-- Jangan panggil require("ai-gemini") di sini (global scope)!
-- local ai_gemini = require("ai-gemini") -- <--- HAPUS BARIS INI JIKA ADA

vim.api.nvim_create_user_command(
    "AIGeminiChat",
    function()
        -- Panggil require di dalam fungsi ini
        require("ai-gemini").start_chat_session()
    end,
    {
        desc = "Start a new AI Gemini chat session",
        nargs = 0,
    }
)

vim.api.nvim_create_user_command(
    "AIGeminiExplain",
    function(args)
        -- Panggil require di dalam fungsi ini
        local ai_gemini = require("ai-gemini")
        -- Cek ini hanya untuk berjaga-jaga, seharusnya sudah dikonfigurasi oleh user di init.lua mereka
        if not ai_gemini or not ai_gemini.opts then
            vim.notify("AI-Gemini: Plugin not configured correctly. Please check your Neovim init.lua.", vim.log.levels.ERROR)
            return
        end

        local selected_text = ""
        if vim.v.selection == "v" or vim.v.selection == "V" or vim.v.selection == "<C-v>" then
             vim.cmd('normal! gv"ay')
             selected_text = vim.fn.getreg('a')
        else
            selected_text = vim.api.nvim_get_current_line()
        end

        if selected_text == "" then
            vim.notify("AI-Gemini: No text selected or current line empty for explanation.", vim.log.levels.WARN)
            return
        end

        ai_gemini.handle_ai_request(
            "Please explain the following code in detail, answering in Chinese if possible and provide example usage:",
            selected_text,
            function(response_content)
                vim.notify("AI-Gemini Explanation:\n" .. response_content, vim.log.levels.INFO)
            end
        )
    end,
    {
        desc = "Explain selected code using AI Gemini",
        range = "%",
    }
)

