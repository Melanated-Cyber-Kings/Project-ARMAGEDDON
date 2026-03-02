#!/bin/bash

#create buckets from command line
aws s3api create-bucket --bucket armageddon-tf-tokyo-theswordpt --region ap-northeast-1 --create-bucket-configuration LocationConstraint=ap-northeast-1

aws s3api create-bucket --bucket armageddon-tf-saopaulo-theswordpt --region sa-east-1 --create-bucket-configuration LocationConstraint=sa-east-1
