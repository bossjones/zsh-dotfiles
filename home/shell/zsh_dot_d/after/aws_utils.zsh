awslookup() {
  # SOURCE: https://engineering.talis.com/articles/bash-awslookup-tool/
  # uses aws cli to lookup instances based on a filter on the Name tag
  # $1 is the filter to use
  # $2 is the output format defaults to 'table'
  # $3 is optional, the value doesn't matter but if passed in will result
  #    in this function printing out the raw command its about to run
  #    for debugging purposes
  cmd="aws ec2 describe-instances --filters \"Name=tag:Name,Values=$1\" --query 'Reservations[].Instances[].[InstanceId,PublicDnsName,PrivateIpAddress,State.Name,InstanceType,join(\`,\`,Tags[?Key==\`Name\`].Value)]' --output ${2:-table}"
  if [ $# -eq 3 ]
  then
    echo "Running $cmd"
  fi
  eval $cmd
}