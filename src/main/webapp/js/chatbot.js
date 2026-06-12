function submitChat(event) {
    if (event) event.preventDefault();
    
    var input = document.getElementById("chatInput");
    var query = input.value.trim();
    if (!query) return;

    // Clear input
    input.value = "";

    // 1. Append User Message
    appendMessage(query, "user");

    // 2. Disable input while loading
    input.disabled = true;
    var form = document.getElementById("chatForm");
    var sendBtn = form.querySelector(".send-btn");
    sendBtn.disabled = true;

    // 3. Show Typing Indicator
    showTypingIndicator();

    // 4. Send request to AIServlet
    var params = new URLSearchParams();
    params.append("action", "chatbot");
    params.append("message", query);

    fetch(window.CONTEXT_PATH + "/api/ai", {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded"
        },
        body: params.toString()
    })
    .then(function(res) {
        if (!res.ok) throw new Error("HTTP error " + res.status);
        return res.json();
    })
    .then(function(data) {
        removeTypingIndicator();
        
        // Append response
        appendMessage(data.text, "bot");
        
        // If the action updated database stock, let's play a subtle visual refresh or notification hint.
        if (data.actionType === "UPDATE" && data.success) {
            // Log update feedback
            console.log("Database update triggered via chatbot query.");
        }
    })
    .catch(function(err) {
        console.error("Chatbot Error: ", err);
        removeTypingIndicator();
        appendMessage("Sorry, I encountered an error while trying to connect to the local AI engine. Make sure XAMPP and your servlet container are running.", "bot");
    })
    .finally(function() {
        input.disabled = false;
        sendBtn.disabled = false;
        input.focus();
    });
}

function appendMessage(text, sender) {
    var container = document.getElementById("chatMessages");
    var bubble = document.createElement("div");
    bubble.className = "chat-bubble " + sender + "-message";
    
    // Simple markdown-to-HTML parser (bold tags and newlines)
    var formattedText = text
        .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>") // bold
        .replace(/• (.*?)\n/g, "<li>$1</li>")            // bullet list items
        .replace(/\n/g, "<br>");                           // newlines
        
    // Clean list formatting wraps if lists are present
    if (formattedText.includes("<li>")) {
        // If there's list items, make sure they are grouped in a list tag
        // Simple search-and-replace for clean rendering
        formattedText = formattedText.replace(/(<li>.*?<\/li>)+/g, "<ul>$&</ul>");
    }

    var time = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    bubble.innerHTML = 
        '<div class="bubble-content">' + formattedText + '</div>' +
        '<span class="bubble-time">' + time + '</span>';

    container.appendChild(bubble);
    scrollChatToBottom();
}

function showTypingIndicator() {
    var container = document.getElementById("chatMessages");
    var indicator = document.createElement("div");
    indicator.className = "chat-bubble bot-message typing-indicator-bubble";
    indicator.id = "typingIndicator";
    
    indicator.innerHTML = 
        '<div class="bubble-content">' +
            '<div class="typing-indicator">' +
                '<span class="typing-dot"></span>' +
                '<span class="typing-dot"></span>' +
                '<span class="typing-dot"></span>' +
            '</div>' +
        '</div>';
        
    container.appendChild(indicator);
    scrollChatToBottom();
}

function removeTypingIndicator() {
    var ind = document.getElementById("typingIndicator");
    if (ind) ind.remove();
}

function scrollChatToBottom() {
    var container = document.getElementById("chatMessages");
    container.scrollTop = container.scrollHeight;
}

function clearChat() {
    if (confirm("Reset chat history?")) {
        var container = document.getElementById("chatMessages");
        container.innerHTML = 
            '<div class="chat-bubble bot-message">' +
                '<div class="bubble-content">' +
                    'Hello! I am your local AI Inventory Assistant. How can I help you today?' +
                '</div>' +
                '<span class="bubble-time">Just now</span>' +
            '</div>';
    }
}
