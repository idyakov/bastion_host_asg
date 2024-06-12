#!/usr/bin/env bash
<<<<<<< HEAD
#
=======

>>>>>>> 7bb0fa90f143468dac30e57a6b9b1dab38cfd38c
# Determine instance-id and current region from metadata
# Retrieve instance ID
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Retrieve availability zone
availability_zone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Extract region from availability zone
# Two $'s here so that terraform templating expands it as is with one $
region=$${availability_zone::-1}

# If the address is already associated (to a deleted instance), then delete that association.
# Important to do this, else we will not be able to associate it with new instance launched by ASG.
association_id=$(aws ec2 describe-addresses --region $region --allocation-ids ${allocation_id} --query 'Addresses[0].AssociationId' --output text)
if [ "$association_id" != "None" ]
then
    echo "Deleting previous EIP association"
    aws ec2 disassociate-address --region $region --association-id $association_id
fi

# Associate the address
echo "Associating EIP"
<<<<<<< HEAD
aws ec2 associate-address --region $region --instance-id $instance_id --allocation-id ${allocation_id}
=======
aws ec2 associate-address --region $region --instance-id $instance_id --allocation-id ${allocation_id}

>>>>>>> 7bb0fa90f143468dac30e57a6b9b1dab38cfd38c
