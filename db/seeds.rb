# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

CollectionHighlight.delete_all

# real collections
CollectionHighlight.create(id:1,druid:'yt502zj0924',image_url:'https://stacks.stanford.edu/image/gd375mm0577/Craig-001_0017_thumb') # Craig
CollectionHighlight.create(id:2,druid:'wz243gf4151',image_url:'https://stacks.stanford.edu/image/mz909yv3823/2011-023Cham-1.0_0001_thumb') # Chambers
CollectionHighlight.create(id:3,druid:'xw162vm3550',image_url:'https://stacks.stanford.edu/image/fc048tp5530/2012-006MANO-1963-b1_2.0_0010_thumb') # Duke Manor
CollectionHighlight.create(id:4,druid:'zv664xj7415',image_url:'https://stacks.stanford.edu/image/zv664xj7415/2006-001PHIL-1953-b1_36.1_0016_thumb') # Phillips
CollectionHighlight.create(id:5,druid:'wn860zc7322',image_url:'https://stacks.stanford.edu/image/qb957rw1430/2011-023DUG-3.0_0015_thumb') # Dugdale

# fixture collections

