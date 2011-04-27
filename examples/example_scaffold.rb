def server
  fork do
    yield
  end
end

def client
  fork do
    yield
  end
end

def run
  Process.waitall
end