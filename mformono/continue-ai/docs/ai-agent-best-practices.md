# AI Agent Best Practices

This document outlines best practices for using AI agents to automate software development tasks. Following these guidelines will help ensure that the agent's actions are predictable, effective, and aligned with your project's goals.

## The Two-Step Approach: Suggestion and Implementation

To maximize the effectiveness of AI agents, we recommend a two-step approach that separates the "thinking" from the "doing." This involves using two different types of AI models for each step:

1. **Suggestion Phase (Reasoning Model)**: Use a powerful reasoning model, such as **Gemini 2.5 Pro**, to analyze the problem, understand the context, and propose a high-level plan. This model excels at understanding complex requirements and breaking them down into smaller, manageable steps.
2. **Implementation Phase (Coding Model)**: Once you have a plan, use a specialized coding model, such as **Claude 3.7 Sonnet**, to implement the changes. These models are optimized for generating high-quality, idiomatic code and are well-suited for the more mechanical task of writing code.

### Why Use This Approach?

- **Better Control**: By separating the planning from the implementation, you have more control over the agent's actions. You can review and approve the plan before any code is written, which reduces the risk of unintended consequences.
- **Higher Quality Results**: Using the right tool for the job leads to better results. Reasoning models are better at high-level planning, while coding models are better at writing code.
- **Easier Debugging**: If something goes wrong, it's easier to identify the source of the problem. If the plan was flawed, you know that the reasoning model needs to be adjusted. If the implementation was incorrect, you know that the coding model needs to be corrected.

## Practical Workflow

1. **Define the Task**: Clearly define the task you want the agent to perform. The more specific you are, the better the results will be.

2. **Request a Suggestion**: Ask the reasoning model to propose a plan for completing the task. For example, you could say:

    > "I want to add a new feature that allows users to export their data as a CSV file. Please provide a step-by-step plan for implementing this feature."

3. **Review the Plan**: Carefully review the plan proposed by the reasoning model. Make sure that it is complete, correct, and aligned with your project's conventions.

4. **Request Implementation**: Once you are satisfied with the plan, ask the coding model to implement it. You can provide the plan as context to the coding model. For example, you could say:

    > "Please implement the following plan:
    > 1. Create a new route `/export` that accepts a `GET` request.
    > 2. In the controller for this route, fetch the user's data from the database.
    > 3. Convert the data to a CSV format.
    > 4. Return the CSV data as a downloadable file."

5. **Verify the Changes**: After the coding model has implemented the changes, verify that they are correct and that they meet your requirements. This may involve running tests, linting the code, and manually testing the new feature.
