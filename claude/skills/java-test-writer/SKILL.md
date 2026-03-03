---
name: java-test-writer
description: Create integration tests using Ability/Assertion patterns with given/when/then structure. Discovers existing patterns first.
category: Testing
tags: [java, testing, integration, ability, assertion]
---

**Purpose**
Write integration tests for Java projects following best practices:
- Ability pattern for test data setup (with builders)
- Assertion pattern for fluent response verification
- Meaningful given/when/then comments

**Guardrails**
- Integration tests are prioritized over unit tests
- Always verify existing patterns in the codebase before creating new ones
- Follow project-specific conventions discovered during exploration
- Keep tests focused on end-to-end behavior
- Do not create unit tests unless explicitly requested or testing isolated logic

**Steps**

1. **Discover existing patterns** - Search for established testing patterns:
   ```
   Search for:
   - **/ability/**/*.java - Ability pattern implementations
   - **/assertion/**/*.java - Assertion pattern implementations
   - **/*IT.java or **/*IntegrationTest.java - Integration test examples
   - **/*E2E.java or **/*E2ETest.java - End-to-end test examples
   - **/test/**/*TestData.java - Test data builders
   ```

2. **If patterns exist**: Read 2-3 representative files to understand:
   - How Abilities are structured (method naming, builder integration)
   - How Assertions extend base classes or are structured
   - How given/when/then comments are formatted
   - What base test class is used (if any)
   - Framework specifics (Spring MockMvc, RestAssured, etc.)

3. **If patterns do NOT exist**: Present the user with example code and ask for confirmation:

   Show example Ability:
   ```java
   @Component
   @RequiredArgsConstructor
   public class {Entity}Ability {
     private final {Entity}Repository repository;

     public void thereIs{Entity}(Consumer<{Entity}Builder>... consumers) {
       for (Consumer<{Entity}Builder> consumer : consumers) {
         {Entity}Builder builder = new {Entity}Builder();
         consumer.accept(builder);
         repository.save(builder.build());
       }
     }
   }
   ```

   Show example Assertion:
   ```java
   public class {Entity}ResponseAssertion extends ResponseAssertion<{Entity}Response> {
     private final {Entity}Response response;

     private {Entity}ResponseAssertion(MvcResult mvcResult) {
       super(mvcResult);
       this.response = getResponseBody({Entity}Response.class);
     }

     public static {Entity}ResponseAssertion assertThat(MvcResult mvcResult) {
       return new {Entity}ResponseAssertion(mvcResult);
     }

     public {Entity}ResponseAssertion hasId(UUID expectedId) {
       Assertions.assertThat(response.id()).isEqualTo(expectedId);
       return this;
     }
   }
   ```

   Ask: "Should I create these testing patterns for your project? Please confirm or suggest modifications."

4. **Write the integration test** following discovered or confirmed patterns:
   - Use `// given: {context}` to describe initial state setup
   - Use `// and: {context}` for additional setup within the same section
   - Use `// when: {action}` to describe the action being tested
   - Use `// then: {expectation}` for assertions
   - Use `// and: {expectation}` for additional assertions

5. **Create supporting classes** as needed:
   - Ability class if testing a new domain
   - Builder class if one doesn't exist for the entity
   - Assertion class for the response type
   - Test data constants class if needed

**Test Structure Template**
```java
@Test
void {methodUnderTest}_{expectedBehavior}() throws Exception {
  // given: {describe initial state}
  {ability}.thereIs{Entity}(builder -> builder.withId(ID).with{Field}(value));

  // and: {additional setup if needed}

  // when: {describe the action}
  MvcResult result = mockMvc
      .perform({httpMethod}("/api/{resource}")
          .with(jwt().jwt(builder -> builder.subject("user"))))
      .andExpect(status().{expectedStatus}())
      .andReturn();

  // then: {describe expected outcome}
  {Entity}ResponseAssertion.assertThat(result)
      .hasId(ID)
      .has{Field}(expectedValue);

  // and: {additional assertions if needed}
}
```

**Reference**
- Check for base test classes: `*IntegrationTest.java`, `*TestBase.java`
- Check for shared assertions: `ResponseAssertion.java` in misc/assertion
- Check for test utilities: `*TestData.java` files
- Spring Boot testing: `@SpringBootTest`, `@AutoConfigureMockMvc`, `@Transactional`
 