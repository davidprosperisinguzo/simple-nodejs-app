const assert = require("assert");
const request = require("supertest");

const app = require("./server");

describe("express", function() {
  it("responds to /", function(done) {
    request(app)
      .get("/")
      .set("Accept", "text/html")
      .expect("Content-Type", /text\/html/)
      .expect(200)
      .expect(function(response) {
        assert.ok(response.text.includes("Hello World"));
        assert.ok(response.text.includes("What this is"));
        assert.ok(response.text.includes("Live runtime"));
        assert.ok(response.text.includes("{{HOSTNAME}}") === false);
        assert.ok(response.text.includes("Container hostname"));
        assert.ok(response.text.includes("Node version"));
        assert.ok(response.text.includes("Server started"));
        assert.ok(response.text.includes("Process uptime"));
      })
      .end(done);
  });
  it("404s everything else", function(done) {
    request(app)
      .get("/foo/bar")
      .expect(404, done);
  });
});
