# SOURCE: https://github.com/unixorn/zsh-quickstart-kit/blob/master/zsh/.zsh_aliases
# aliases borrowed from unixorn
alias historysummary="history | awk '{a[\$2]++} END{for(i in a){printf \"%5d\t%s\n\",a[i],i}}' | sort -rn | head"

# A couple of different external IP lookups depending on which is down.
alias external_ip="curl -s icanhazip.com"
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

# Show laptop's IP addresses
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"

# SSH stuff
# Pass our credentials by default
alias sshA='ssh -A'
alias ssh-A='ssh -A'
alias ssh-unkeyed='/usr/bin/ssh'
alias ssh_unkeyed='/usr/bin/ssh'

alias scp-no-hostchecks='scp -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias ssh-no-hostchecks='ssh -A -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias scp_no_hostchecks='scp -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias ssh_no_hostchecks='ssh -A -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

# Set up even more shortcuts because I am that lazy a typist.
alias nh-scp=scp-no-hostchecks
alias nh-ssh=ssh-no-hostchecks
alias nh_scp=scp-no-hostchecks
alias nh_ssh=ssh-no-hostchecks
alias nhscp=scp-no-hostchecks
alias nhssh=ssh-no-hostchecks

# Strip color codes from commands that insist on spewing them so we can
# pipe them into files cleanly.
alias stripcolors='sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'

# lists zombie processes
zombie() {
  ps aux | awk '{if ($8=="Z") { print $2 }}'
}
alias zombies=zombie
