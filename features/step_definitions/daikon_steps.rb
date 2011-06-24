When /^I set the "([^"]+)" variable to "([^"]+)"$/ do |key, value|
  @env_vars ||= []
  @env_vars << key
  set_env(key, value)
end

When /^I wait (\d+) seconds?$/ do |seconds|
  sleep seconds.to_i
end

Then /^the output should contain the current version number$/ do
  all_output.should =~ /Daikon v#{Daikon::VERSION}/
end
