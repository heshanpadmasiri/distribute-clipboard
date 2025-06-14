import ballerina/http;
import ballerina/io;
import ballerina/lang.'string;

service / on new http:Listener(8080) {

    // Serve the main HTML page
    resource function get .() returns http:Response|error {
        http:Response response = new;
        string htmlContent = check getMainHtml();
        response.setTextPayload(htmlContent, "text/html");
        response.setHeader("Cache-Control", "no-cache");
        return response;
    }

    // API endpoint to get hello world message
    resource function get api/hello() returns http:Response|error {
        http:Response response = new;
        response.setTextPayload("<h1 id='message' class='text-center text-blue-600 text-4xl font-bold animate-pulse'>Hello, World from HTMX!</h1>", "text/html");
        return response;
    }

    // API endpoint to update the message
    resource function post api/update() returns http:Response|error {
        http:Response response = new;
        response.setTextPayload("<h1 id='message' class='text-center text-green-600 text-4xl font-bold'>Message Updated! 🎉</h1>", "text/html");
        return response;
    }

    // API endpoint to handle text and file uploads
    resource function post api/upload(http:Request req) returns http:Response|error {
        http:Response response = new;

        // Parse multipart form data
        var bodyParts = req.getBodyParts();
        if (bodyParts is error) {
            response.setTextPayload("<div class='bg-red-500/20 rounded-lg p-4 border border-red-500/30'><p class='text-white'>❌ Error parsing form data</p></div>", "text/html");
            return response;
        }

        string resultHtml = "<div class='bg-green-500/20 rounded-lg p-4 border border-green-500/30'>";
        boolean hasContent = false;

        foreach var part in bodyParts {
            var contentDisposition = part.getContentDisposition();
            string partName = contentDisposition.name is string ? contentDisposition.name : "";

            if (partName == "text") {
                // Handle text input
                var textContent = part.getText();
                if (textContent is string && 'string:trim(textContent) != "") {
                    io:println("📝 Text received: " + textContent);
                    resultHtml += "<h3 class='text-white font-semibold mb-2'>✅ Text uploaded:</h3>";
                    resultHtml += "<p class='text-white/90 bg-white/10 rounded p-2 mb-3'>" + textContent + "</p>";
                    hasContent = true;
                }
            } else if (partName == "file") {
                // Handle file upload
                string fileName = contentDisposition.fileName is string ? contentDisposition.fileName : "";
                if (fileName != "") {
                    io:println("📁 File received: " + fileName);
                    resultHtml += "<h3 class='text-white font-semibold mb-2'>✅ File uploaded:</h3>";
                    resultHtml += "<p class='text-white/90 bg-white/10 rounded p-2 mb-3'>📄 " + fileName + "</p>";
                    hasContent = true;
                }
            }
        }

        if (!hasContent) {
            resultHtml = "<div class='bg-yellow-500/20 rounded-lg p-4 border border-yellow-500/30'>";
            resultHtml += "<p class='text-white'>⚠️ No content provided. Please enter text or select a file.</p>";
        } else {
            resultHtml += "<p class='text-green-200 text-sm'>🎉 Upload successful!</p>";
        }

        resultHtml += "</div>";
        response.setTextPayload(resultHtml, "text/html");

        return response;
    }
}

function getMainHtml() returns string|error {
    string htmlContent = check io:fileReadString("index.html");
    return htmlContent;
}

public function main() {
    io:println("🚀 Starting Ballerina HTTP server...");
    io:println("📡 Server running on http://localhost:8080");
    io:println("🌐 Open your browser and visit the URL above!");
}
