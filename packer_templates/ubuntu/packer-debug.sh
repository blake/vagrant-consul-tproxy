# Enable verbose logging
export PACKER_LOG=1

# Write log to local file
export PACKER_LOG_PATH="packer.log"

# The SSH key used to access the instance can be found in the `output_directory`
# for the build under `.vagrant/machines/source/virtualbox/private_key`. The
# output directory defaults to `output-<BUILDNAME>` where `BUILDNAME` is the
# name defined in the `source` section of the template.
#
# For example, if the build name is `ubuntu_22_04`, the private key will be
# found in `output-ubuntu_22_04/.vagrant/machines/source/virtualbox/private_key`.
#
# The instance can then be accessed via SSH using the following command:
#
# ssh -i <private_key> -o StrictHostKeyChecking=no -l vagrant -p 2222 127.0.0.1
