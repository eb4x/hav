Facter.add(:openssl_passfile) do
  setcode do
    file_path = '/opt/himlar/provision/ca/passfile'
    if File.exist?(file_path)
      file_content = File.read(file_path).strip
      file_content
    else
      nil
    end
  end
end
