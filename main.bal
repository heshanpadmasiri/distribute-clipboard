import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/lang.'string;
import ballerina/mime;

type TextUpload string;

type FileUpload record {
    string fileName;
    string filePath;
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

    resource function get api/download/[string fileName]() returns http:Response|error {
        http:Response response = new;
        string filePath = "./data/" + fileName;

        // Check if file exists
        boolean fileExists = check file:test(filePath, file:EXISTS);
        if (!fileExists) {
            response.statusCode = 404;
            response.setTextPayload("File not found");
            return response;
        }

        // Read file content
        byte[] fileContent = check io:fileReadBytes(filePath);

        // Set response headers for download
        response.setBinaryPayload(fileContent);
        response.setHeader("Content-Disposition", string `attachment; filename="${fileName}"`);

        // Try to determine content type based on file extension
        string contentType = getContentType(fileName);
        response.setHeader("Content-Type", contentType);

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
                io:println(`📝 Text received: ${textContent}`);
                uploads.push(textContent);
                hasNewContent = true;
            }
        } else if (partName == "file") {
            string fileName = contentDisposition.fileName is string ? contentDisposition.fileName : "";
            if (fileName != "") {
                // Save file to data directory
                var fileContent = part.getByteArray();
                if (fileContent is byte[]) {
                    string filePath = "./data/" + fileName;
                    var writeResult = io:fileWriteBytes(filePath, fileContent);
                    if (writeResult is error) {
                        io:println(`❌ Error saving file: ${writeResult.message()}`);
                    } else {
                        io:println(`📁 File saved: ${fileName} to ${filePath}`);
                        FileUpload fileUpload = {fileName: fileName, filePath: filePath};
                        uploads.push(fileUpload);
                        hasNewContent = true;
                    }
                }
            }
        }
    }

    return hasNewContent;
}

function generateUploadsHtml(boolean hasNewContent) returns string {
    string resultHtml = "";

    if (!hasNewContent && uploads.length() == 0) {
        resultHtml = string `<div class='bg-yellow-500/20 rounded-lg p-4 border border-yellow-500/30'><p class='text-white'>⚠️ No content provided. Please enter text or select a file.</p></div>`;
        return resultHtml;
    }

    if (hasNewContent) {
        resultHtml += string `<div class='bg-green-500/20 rounded-lg p-2 border border-green-500/30 mb-4'><p class='text-green-200 text-sm'>🎉 Upload successful!</p></div>`;
    }

    resultHtml += string `<div class='bg-blue-500/20 rounded-lg p-4 border border-blue-500/30'><h3 class='text-white font-semibold mb-4'>📋 All Uploads (${uploads.length().toString()}):</h3>`;

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
        itemHtml += "<span class='text-xs text-white/60 ml-2'>(click to copy)</span>";
        itemHtml += "</div>";
        itemHtml += string `<p class='text-white/90 ml-4 clipboard-text cursor-pointer hover:bg-white/10 p-2 rounded' onclick="copyToClipboard('${upload}', this)" title="Click to copy to clipboard">${upload}</p>`;
    } else if (upload is FileUpload) {
        itemHtml += "<div class='flex items-center mb-1'>";
        itemHtml += "<span class='text-green-300 font-medium'>📄 File:</span>";
        itemHtml += "</div>";
        itemHtml += string `<p class='text-white/90 ml-4'><a href='/api/download/${upload.fileName}' class='text-blue-400 hover:text-blue-300 underline cursor-pointer' download='${upload.fileName}'>${upload.fileName}</a></p>`;
    }

    itemHtml += "</div>";
    return itemHtml;
}

function getContentType(string fileName) returns string {
    if (fileName.includes(".")) {
        int? lastDotIndex = fileName.lastIndexOf(".");
        if (lastDotIndex is int && lastDotIndex >= 0) {
            string extension = fileName.substring(lastDotIndex + 1).toLowerAscii();
            match extension {
                "txt" => {
                    return "text/plain";
                }
                "html" => {
                    return "text/html";
                }
                "css" => {
                    return "text/css";
                }
                "js" => {
                    return "application/javascript";
                }
                "json" => {
                    return "application/json";
                }
                "pdf" => {
                    return "application/pdf";
                }
                "png" => {
                    return "image/png";
                }
                "jpg"|"jpeg" => {
                    return "image/jpeg";
                }
                "gif" => {
                    return "image/gif";
                }
                "svg" => {
                    return "image/svg+xml";
                }
                "zip" => {
                    return "application/zip";
                }
                "xml" => {
                    return "application/xml";
                }
                _ => {
                    return "application/octet-stream";
                }
            }
        }
    }
    return "application/octet-stream";
}

public function main() {
    io:println("🚀 Starting Ballerina HTTP server...");
    io:println("📡 Server running on http://localhost:8080");
    io:println("🌐 Open your browser and visit the URL above!");
}
