def server
  fork do
    $0 = 'server'
    yield
  end
end

def client
  fork do
    $0 = 'client'
    yield
  end
end

def run
  Process.waitall
end