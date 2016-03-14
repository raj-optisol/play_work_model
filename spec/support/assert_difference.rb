def assert_difference(executable, how_many = 1, &block)
  before = yield_executable(executable)
  yield
  after = yield_executable(executable)
  after.should == before + how_many
end

def yield_executable(executable)
  if executable.is_a?(String)
    eval(executable) 
  else
    executable.call
  end
end

def assert_no_difference(executable,  &block)
  before = yield_executable(executable)
  yield
  after = yield_executable(executable)
  after.should == before
end
