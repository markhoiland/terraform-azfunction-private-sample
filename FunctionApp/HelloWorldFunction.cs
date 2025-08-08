using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;

namespace FunctionApp
{
    public class HelloWorldFunction
    {
        private readonly ILogger _logger;

        public HelloWorldFunction(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<HelloWorldFunction>();
        }

        [Function("HelloWorld")]
        public async Task<HttpResponseData> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/plain; charset=utf-8");

            await response.WriteStringAsync("Hello World from Azure Functions!");

            return response;
        }
    }
}
