import ballerina/http;
import ballerina/io;
import ballerina/lang.'string;

// Type definitions
type TextUpload string;

type FileUpload record {
    string fileName;
};

type Upload TextUpload|FileUpload;

// Global array to store all uploads
Upload[] uploads = [];

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

        boolean hasNewContent = false;

        foreach var part in bodyParts {
            var contentDisposition = part.getContentDisposition();
            string partName = contentDisposition.name is string ? contentDisposition.name : "";

            if (partName == "text") {
                // Handle text input
                var textContent = part.getText();
                if (textContent is string && 'string:trim(textContent) != "") {
                    io:println("📝 Text received: " + textContent);
                    // Add text to uploads array
                    uploads.push(textContent);
                    hasNewContent = true;
                }
            } else if (partName == "file") {
                // Handle file upload
                string fileName = contentDisposition.fileName is string ? contentDisposition.fileName : "";
                if (fileName != "") {
                    io:println("📁 File received: " + fileName);
                    // Add file to uploads array
                    FileUpload fileUpload = {fileName: fileName};
                    uploads.push(fileUpload);
                    hasNewContent = true;
                }
            }
        }

        // Generate HTML response showing all uploads
        string resultHtml = "";

        if (!hasNewContent && uploads.length() == 0) {
            resultHtml = "<div class='bg-yellow-500/20 rounded-lg p-4 border border-yellow-500/30'>";
            resultHtml += "<p class='text-white'>⚠️ No content provided. Please enter text or select a file.</p>";
            resultHtml += "</div>";
        } else {
            if (hasNewContent) {
                resultHtml += "<div class='bg-green-500/20 rounded-lg p-2 border border-green-500/30 mb-4'>";
                resultHtml += "<p class='text-green-200 text-sm'>🎉 Upload successful!</p>";
                resultHtml += "</div>";
            }

            resultHtml += "<div class='bg-blue-500/20 rounded-lg p-4 border border-blue-500/30'>";
            resultHtml += "<h3 class='text-white font-semibold mb-4'>📋 All Uploads (" + uploads.length().toString() + "):</h3>";

            // Display all uploads
            foreach int i in 0 ..< uploads.length() {
                Upload upload = uploads[i];
                resultHtml += "<div class='bg-white/10 rounded p-3 mb-2'>";

                if (upload is TextUpload) {
                    resultHtml += "<div class='flex items-center mb-1'>";
                    resultHtml += "<span class='text-blue-300 font-medium'>📝 Text #" + (i + 1).toString() + ":</span>";
                    resultHtml += "</div>";
                    resultHtml += "<p class='text-white/90 ml-4'>" + upload + "</p>";
                } else if (upload is FileUpload) {
                    resultHtml += "<div class='flex items-center mb-1'>";
                    resultHtml += "<span class='text-green-300 font-medium'>📄 File #" + (i + 1).toString() + ":</span>";
                    resultHtml += "</div>";
                    resultHtml += "<p class='text-white/90 ml-4'>" + upload.fileName + "</p>";
                }

                resultHtml += "</div>";
            }

            resultHtml += "</div>";
        }

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
