import ballerina/http;
import ballerina/io;

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
