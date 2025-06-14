import ballerina/http;
import ballerina/io;
import ballerina/lang.'string;
import ballerina/mime;

type TextUpload string;

type FileUpload record {
    string fileName;
};

type Upload TextUpload|FileUpload;

Upload[] uploads = [];

service / on new http:Listener(8080) {

    resource function get .() returns http:Response|error {
        http:Response response = new;
        string htmlContent = check getMainHtml();
        response.setTextPayload(htmlContent, "text/html");
        response.setHeader("Cache-Control", "no-cache");
        return response;
    }

    resource function get api/hello() returns http:Response|error {
        http:Response response = new;
        response.setTextPayload("<h1 id='message' class='text-center text-blue-600 text-4xl font-bold animate-pulse'>Hello, World from HTMX!</h1>", "text/html");
        return response;
    }

    resource function post api/update() returns http:Response|error {
        http:Response response = new;
        response.setTextPayload("<h1 id='message' class='text-center text-green-600 text-4xl font-bold'>Message Updated! 🎉</h1>", "text/html");
        return response;
    }

    resource function post api/upload(http:Request req) returns http:Response|error {
        http:Response response = new;

        var bodyParts = req.getBodyParts();
        if (bodyParts is error) {
            response.setTextPayload("<div class='bg-red-500/20 rounded-lg p-4 border border-red-500/30'><p class='text-white'>❌ Error parsing form data</p></div>", "text/html");
            return response;
        }

        response.setTextPayload(generateUploadsHtml(processUploads(bodyParts)), "text/html");
        return response;
    }
}

function getMainHtml() returns string|error {
    string htmlContent = check io:fileReadString("index.html");
    return htmlContent;
}

function processUploads(mime:Entity[] bodyParts) returns boolean {
    boolean hasNewContent = false;

    foreach var part in bodyParts {
        var contentDisposition = part.getContentDisposition();
        string partName = contentDisposition.name is string ? contentDisposition.name : "";

        if (partName == "text") {
            var textContent = part.getText();
            if (textContent is string && 'string:trim(textContent) != "") {
                io:println("📝 Text received: " + textContent);
                uploads.push(textContent);
                hasNewContent = true;
            }
        } else if (partName == "file") {
            string fileName = contentDisposition.fileName is string ? contentDisposition.fileName : "";
            if (fileName != "") {
                io:println("📁 File received: " + fileName);
                FileUpload fileUpload = {fileName: fileName};
                uploads.push(fileUpload);
                hasNewContent = true;
            }
        }
    }

    return hasNewContent;
}

function generateUploadsHtml(boolean hasNewContent) returns string {
    string resultHtml = "";

    if (!hasNewContent && uploads.length() == 0) {
        resultHtml = "<div class='bg-yellow-500/20 rounded-lg p-4 border border-yellow-500/30'>";
        resultHtml += "<p class='text-white'>⚠️ No content provided. Please enter text or select a file.</p>";
        resultHtml += "</div>";
        return resultHtml;
    }

    if (hasNewContent) {
        resultHtml += "<div class='bg-green-500/20 rounded-lg p-2 border border-green-500/30 mb-4'>";
        resultHtml += "<p class='text-green-200 text-sm'>🎉 Upload successful!</p>";
        resultHtml += "</div>";
    }

    resultHtml += "<div class='bg-blue-500/20 rounded-lg p-4 border border-blue-500/30'>";
    resultHtml += "<h3 class='text-white font-semibold mb-4'>📋 All Uploads (" + uploads.length().toString() + "):</h3>";

    foreach Upload upload in uploads {
        resultHtml += toHTML(upload);
    }

    resultHtml += "</div>";
    return resultHtml;
}

function toHTML(Upload upload) returns string {
    string itemHtml = "<div class='bg-white/10 rounded p-3 mb-2'>";

    if (upload is TextUpload) {
        itemHtml += "<div class='flex items-center mb-1'>";
        itemHtml += "<span class='text-blue-300 font-medium'>📝 Text:</span>";
        itemHtml += "</div>";
        itemHtml += "<p class='text-white/90 ml-4'>" + upload + "</p>";
    } else if (upload is FileUpload) {
        itemHtml += "<div class='flex items-center mb-1'>";
        itemHtml += "<span class='text-green-300 font-medium'>📄 File:</span>";
        itemHtml += "</div>";
        itemHtml += "<p class='text-white/90 ml-4'>" + upload.fileName + "</p>";
    }

    itemHtml += "</div>";
    return itemHtml;
}

public function main() {
    io:println("🚀 Starting Ballerina HTTP server...");
    io:println("📡 Server running on http://localhost:8080");
    io:println("🌐 Open your browser and visit the URL above!");
}
