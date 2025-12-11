import OpenAI from "openai";

const client = new OpenAI(); // uses OPENAI_API_KEY from env

async function main() {
  const response = await client.responses.create({
    model: "gpt-4.1-mini",
    input: "Write a short hello message in JavaScript comments.",
  });

  console.log(response.output_text);
}

main().catch(console.error);

