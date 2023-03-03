-- P1 --

-- Q1 --
with 
helper(id) as(
    select id from tag where name in :taglist
),
person_cond1(id, tags) as(
    select personid, array_agg(tagid) as tag_ids
    from person_hasinterest_tag
    where tagid in (select id from helper)
    group by personid
),
condition1(personid, tags) as(
    select id, tags from person_cond1 where array_length(tags,1) >= :K
),
rem_friends(person1id, person2id) as (
    select p1.person1id, p1.person2id
    from person_knows_person p1, condition1
    where p1.person1id = condition1.personid and p1.person2id in (select personid from condition1)

    union

    select p1.person2id, p1.person1id
    from person_knows_person p1, condition1
    where p1.person2id = condition1.personid  and p1.person1id in (select personid from condition1)
),
friends(person1id, person2id) as(
    select p1.person1id, p1.person2id
    from person_knows_person p1, condition1
    where p1.person1id = condition1.personid

    union

    select p1.person2id, p1.person1id
    from person_knows_person p1, condition1
    where p1.person2id = condition1.personid    
),
array_friends(personid, friendlist) as(
    select person1id, array_agg(person2id)
    from friends
    group by person1id
),
validposts(postid, creatorid) as (
    select id, creatorpersonid from post
    where creationdate < :lastdate
),
postlike(personid, postid, creatorid) as (
    select distinct pp1.personid, pp1.postid, v1.creatorid
    from person_likes_post pp1, condition1, validposts v1
    where pp1.personid = condition1.personid and pp1.postid = v1.postid
),
validcomments(commentid, creatorid) as (
    select id, creatorpersonid from comment
    where length > :commentlength
),
commentlike(personid, commentid, creatorid) as (
    select distinct pc1.personid, pc1.commentid, v1.creatorid
    from person_likes_comment pc1, condition1, validcomments v1
    where pc1.personid = condition1.personid and pc1.commentid = v1.commentid
),
liked_post(personid, creatorid, post_ids) as (
    select personid, creatorid, array_agg(postid) as post_ids
    from postlike
    group by personid, creatorid
),
liked_posts(personid, creatorid, post_ids) as (
    select personid, creatorid, post_ids
    from liked_post
    join friends on personid = person1id and creatorid = person2id
),
common_posts(person1_id, person2_id, creatorid, common_post1, common_post2) as (
    select
        p1.personid as person1_id,
        p2.personid as person2_id,
        p1.creatorid,
        p1.post_ids as common_post1,
        p2.post_ids as common_post2
    from
        liked_posts p1
        join liked_posts p2 on p1.personid <> p2.personid and p1.creatorid = p2.creatorid
),
liked_comment(personid, creatorid, comment_ids) as (
    select personid, creatorid, array_agg(commentid) as comment_ids
    from commentlike
    group by personid, creatorid
),
liked_comments(personid, creatorid, comment_ids) as (
    select personid, creatorid, comment_ids
    from liked_comment
    join friends on personid = person1id and creatorid = person2id
),
common_comments(person1_id, person2_id, creatorid, common_comment1, common_comment2) as (
    select
        p1.personid as person1_id,
        p2.personid as person2_id,
        p1.creatorid,
        p1.comment_ids as common_comment1,
        p2.comment_ids as common_comment2
    from
        liked_comments p1
        join liked_comments p2 on p1.personid <> p2.personid and p1.creatorid = p2.creatorid
),
intersect_posts(interest, person1_id, person2_id) as  (
    select array
        (
            select unnest(common_posts.common_post1)
            intersect
            select unnest(common_posts.common_post2)
        ),
    common_posts.person1_id,
    common_posts.person2_id
    from common_posts
),
intersect_comments(interest, person1_id, person2_id) as  (
    select array
        (
            select unnest(common_comments.common_comment1)
            intersect
            select unnest(common_comments.common_comment2)
        ),
    common_comments.person1_id,
    common_comments.person2_id
    from common_comments
),
num_of_commen(person1_id, person2_id, interest) as  (
    select person1_id, person2_id, coalesce(array_length(interest,1),0)
    from intersect_comments
),
num_of_pos(person1_id, person2_id, interest) as  (
    select person1_id, person2_id, coalesce(array_length(interest,1),0)
    from intersect_posts
),
num_of_comment(person1_id, person2_id, interest) as  (
    select person1_id, person2_id, sum(interest)
    from num_of_commen
    group by person1_id, person2_id
),
num_of_post(person1_id, person2_id, interest) as  (
    select person1_id, person2_id, sum(interest)
    from num_of_pos
    group by person1_id, person2_id
),
combin(person1_id, person2_id, interest) as (
    SELECT 
        p.person1_id AS person1_id, 
        p.person2_id AS person2_id,
        COALESCE(c.interest, 0) + COALESCE(p.interest, 0) AS total 
    FROM 
        num_of_comment c 
    FULL OUTER JOIN 
        num_of_post p 
    ON 
        c.person1_id = p.person1_id  AND c.person2_id = p.person2_id 
),
hel(person1_id, person2_id) as (
    select person1_id, person2_id
    from combin
    where interest >= :X and person1_id < person2_id

    except

    select person1id, person2id
    from rem_friends
),
helperr(id) as (
    select person1_id from hel
    union
    select person2_id from hel
),
condition11(personid, tags) as(
    select personid, tags
    from condition1, helperr
    where personid = id
),
refining1(id1, id2, tag1, tag2) as(
    select
        p1.personid as person1_id,
        p2.personid as person2_id,
        p1.tags as common_post1,
        p2.tags as common_post2
    from
        condition11 p1
        join condition11 p2 on p1.personid < p2.personid
),
intersect_refining1(tag, id1, id2) as(
    select array
        (
            select unnest(refining1.tag1)
            intersect
            select unnest(refining1.tag2)
        ),
    refining1.id1,
    refining1.id2
    from refining1
),
final_refine1(id1, id2) as(
    select id1, id2
    from intersect_refining1
    where array_length(tag,1) >= :K
),
another_table(id1, id2) as (
    select person1_id , person2_id
    from final_refine1, hel
    where id1 = person1_id and id2 = person2_id
),
help(person1_id, person2_id) as (
    select person1_id, person2_id
    from hel

    intersect

    select id1, id2
    from another_table
),
brain_fry(person1_id, person2_id, set1) as (
    select person1_id, person2_id, friendlist
    from help, array_friends
    where person1_id = personid
),
brain_fry2(person1_id, person2_id, set1, set2) as (
    select person1_id, person2_id, set1, friendlist
    from brain_fry, array_friends
    where person2_id = personid
),
brain_fry3(set1, person1_id, person2_id) as (
    select array
    (
        select unnest(set1)
        intersect
        select unnest(set2)
    ),
    person1_id, person2_id
    from brain_fry2
),
brain_fry4(person1sid, person2sid, mutualfriendcount) as (
    select person1_id, person2_id, array_length(set1,1) as count
    from brain_fry3
)
select person1sid, person2sid, mutualfriendcount from brain_fry4 order by person1sid, mutualfriendcount desc, person2sid;


-- C1 --





-- P2 --

-- Q2 --
with 
placeid(countryid) as (
    select id from place where place.name = :country_name and type = 'Country'
),
validpeople(id, birthday) as (
    select id, birthday from person where creationdate > :startdate and creationdate < :enddate
    and locationcityid in (select id from place, placeid where partofplaceid = placeid.countryid)
),
universities(personid, universityid, birthmonth) as (
    select person_studyat_university.personid, person_studyat_university.universityid, date_part(
    'month', validpeople.birthday
    ) as "month"
    from person_studyat_university, validpeople where person_studyat_university.personid = validpeople.id and person_studyat_university.universityid is not null
),
same_university_friends(person1id, person2id, universityid, birthmonth) as (
    select u1.personid , u2.personid, u1.universityid, u1.birthmonth
    from universities u1, universities u2 
    where u1.personid < u2.personid and u1.universityid = u2.universityid and u1.birthmonth = u2.birthmonth
),
valid_friends(person1id, person2id, universityid, birthmonth) as (
    select same_university_friends.person1id, same_university_friends.person2id, same_university_friends.universityid, same_university_friends.birthmonth
    from same_university_friends, person_knows_person
    where person_knows_person.person1id = same_university_friends.person1id and person_knows_person.person2id = same_university_friends.person2id
),
triplets(person1id, person2id, person3id) as (
    select v1.person1id, v1.person2id, v2.person2id
    from valid_friends v1, valid_friends v2
    where v1.person2id = v2.person1id
),
inall(person1id, person2id, person3id) as (
    select t1.person1id, t1.person2id, t1.person3id
    from triplets t1, valid_friends v1
    where t1.person1id = v1.person1id and t1.person3id = v1.person2id
)
select count(*) from inall;

-- C2 --





-- P3 --

-- Q3 --
with TagDateTable as
(
    select Postid as msgid, creationdate, TagId
    from Post_hasTag_Tag
    where creationdate >= :begindate
    and creationdate <= :enddate
    union
    select commentid as msgid, creationdate, TagId
    from Comment_hasTag_Tag
    where creationdate >= :begindate
    and creationdate <= :enddate
), firstInterval as
(
    select TagId, count(*) as msgCount
    from TagDateTable
    where creationdate <= :middate
    group by TagId
    having count(*) >= 5
), secondInterval as
(
    select TagId, count(*) as msgCount
    from TagDateTable
    where creationdate >= :middate
    group by TagId
), validTags as
(
    select firstInterval.TagId
    from firstInterval, secondInterval
    where firstInterval.msgCount >= 5*secondInterval.msgCount
    and firstInterval.TagId = secondInterval.TagId
    and secondInterval.msgCount >= 1
), validTagClass as
(
    select Tag.TypeTagClassId as tagid, TagClass.name as tagclassname
    from validTags, Tag, TagClass
    where validTags.TagId = Tag.Id
    and Tag.TypeTagClassId = TagClass.Id
)
select tagclassname, count(*) as count
from validTagClass
group by tagclassname
order by count desc, tagclassname;


-- C3 --







-- P4 --
create index idx_comment_id on comment(id);
create index idx_comment_postid on comment(parentpostid);
create index idx_comment_commentid on comment(parentcommentid);
create index idx_post_hashastag_id on Post_hasTag_Tag(tagid);
create index idx_comment_hashastag_id on Comment_hasTag_Tag(tagid);
create index idx_post_hashastag_postid on Post_hasTag_Tag(postid);
create index idx_comment_hashastag_commentid on Comment_hasTag_Tag(commentid);
create index idx_tag_id on Tag(id);

-- Q4 --
with t1 as
(
    select id, parentpostid
    from comment
), postReply as
(
    select parentpostid as msgid, count(*) as replyComments
    from t1
    group by parentpostid
    having count(*) >= :X
), t2 as 
(
    select id, parentcommentid
    from comment
), commentReply as
(
    select parentcommentid as msgid, count(*) as replyComments
    from t2
    group by parentcommentid
    having count(*) >= :X
), tagAttachedpost as
(
    select msgid, tagid
    from postReply, Post_hasTag_Tag
    where postReply.msgid = Post_hasTag_Tag.postid
), tagAttachedcomment as
(
    select msgid, tagid
    from commentReply, Comment_hasTag_Tag
    where commentReply.msgid = Comment_hasTag_Tag.commentid
), tagAttachedTemp as
(
    select tagid, count(*) as num
    from tagAttachedpost
    group by tagid
    union all
    select tagid, count(*) as num
    from tagAttachedcomment
    group by tagid
), tagAttached as
(
    select tagid, sum(num) as count
    from tagAttachedTemp
    group by tagid
)
select Tag.name as tagname, count
from tagAttached, Tag
where tagAttached.tagid = Tag.id
order by count desc, tagname
limit 10;


-- C4 --
drop index idx_comment_id;
drop index idx_comment_postid;
drop index idx_comment_commentid;
drop index idx_post_hashastag_id;
drop index idx_comment_hashastag_id;
drop index idx_post_hashastag_postid;
drop index idx_comment_hashastag_commentid;
drop index idx_tag_id;



-- P5 --
create index idx_place_name on place (name);
create index idx_person_id on person (id);
create index idx_tagclass_name on tagclass (name);
create index idx_person_locationcityid on person (locationcityid);
create index idx_forum_moderationid on forum (ModeratorPersonId);
create index idx_post_containerforumid on post (ContainerForumId);
create index idx_tag_id on tag (id);
create index idx_forum_id on forum (id);
create index idx_post_hashastag_id on post_hastag_tag (tagid);

-- Q5 --
with validCityLocationId as
(
    select p1.id
    from Place p1, Place p2
    where p2.name = :country_name
    and p1.partofplaceid = p2.id
), validPersonId as
(
    select distinct Person.id
    from Person, validCityLocationId
    where Person.LocationCityId = validCityLocationId.id
), validForums as
(
    select distinct f1.id
    from Forum f1, validPersonId
    where f1.ModeratorPersonId = validPersonId.id
), validPosts as
(
    select distinct p1.id as postid, v1.id as forumid
    from validForums v1, Post p1
    where v1.id = p1.ContainerForumId
), relevantPostTagTable as
(
    select distinct t1.postid
    from Post_hasTag_Tag as t1, Tag as t2, TagClass as t3
    where t1.tagid = t2.id
    and t2.TypeTagClassId = t3.id
    and t3.name = :tagclass
), t1 as
(
    select distinct v1.forumid
    from validPosts as v1, relevantPostTagTable as v2
    where v1.postid = v2.postid
), t2 as
(
    select distinct t1.forumid, p1.id as postid
    from t1, Post p1
    where t1.forumid = p1.ContainerForumId
), tagForumTableTemp as
(
    select t2.forumid, t2.postid, p1.tagid
    from t2, Post_hasTag_Tag as p1
    where t2.postid = p1.postid
), tagForumTable as
(
    select distinct forumid, tagid, count(*) as count
    from tagForumTableTemp
    group by forumid, tagid
), maxTagTable as
(
    select t1.forumid, t1.tagid, t1.count
    from tagForumTable t1
    join (
        select distinct forumid, max(count) as maxCount
        from tagForumTable
        group by forumid
    ) t2
    on t1.forumid = t2.forumid
    and t1.count = t2.maxCount
), forumName as
(
    select forumid, title as forumtitle, tagid, count
    from maxTagTable, Forum
    where maxTagTable.forumid = Forum.id
), tagName as
(
    select forumid, forumtitle, name as mostpopulartagname, count
    from forumName, Tag
    where forumName.tagid = Tag.id
)
select distinct *
from tagName
order by count desc, forumid, forumtitle, mostpopulartagname;

-- C5 --

drop index idx_place_name;
drop index idx_person_id;
drop index idx_tagclass_name;
drop index idx_person_locationcityid;
drop index idx_forum_moderationid;
drop index idx_post_containerforumid;
drop index idx_tag_id;
drop index idx_forum_id;
drop index idx_post_hashastag_id;