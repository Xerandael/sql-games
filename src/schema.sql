create schema absrec;

---------------------------------------------------------------------------------------------------------------------
create table absrec.sources (
    url             varchar(128)      not null,
    plugin          varchar(64)       not null,
    last_update     time,
);
create unique index  absrec_sources  on absrec.sources(url,plugin);


---------------------------------------------------------------------------------------------------------------------
create table absrec.forums (
    source_url      varchar(128),
    name            varchar(128)      not null    primary key,
    creation        time              not null
);
create unique index  absrec_forums_local     on absrec.forums(name)       where source_url is null;
create unique index  absrec_forums_name      on absrec.forums(name);
create index         absrec_forums_creation  on absrec.forums(creation);


---------------------------------------------------------------------------------------------------------------------
create table absrec.invitations (
    key             varchar(64)       not null    primary key,
    expiration      time
);
create unique index  absrec_key_uniqueness  on absrec.invitations(key);


---------------------------------------------------------------------------------------------------------------------
create table absrec.users (
    pubkey          bytea             not null    primary key,
    name            varchar(24)       not null,
    last_read_time  time              not null,
    invitation_key  varchar(64)       not null    references absrec.invitations(key)
);
create unique index  absrec_user_pubkeys        on absrec.users(pubkey);
create unique index  absrec_inv_key_uniqueness  on absrec.users(invitation_key);


---------------------------------------------------------------------------------------------------------------------
create table absrec.forum_users (
    forum_name      varchar(128)      not null    references absrec.forums(name),
    user_pubkey     bytea             not null    references absrec.users(pubkey)
);
create unique index  absrec_forum_users  on absrec.forum_users(forum_name,user_pubkey);


---------------------------------------------------------------------------------------------------------------------
create table absrec.topics (
    name            varchar(128)      not null,
    creation        time              not null,
    --------------- ----------------- ------------ -----------------------------------
    forum_name      varchar(128)      not null     references absrec.forums(name),
    creator         bytea             not null     references absrec.users(pubkey)
);
create unique index  absrec_topics_forum_user_time  on absrec.topics(forum_name,creator,creation);
create index         absrec_topics_forum_time       on absrec.topics(forum_name,creation);


---------------------------------------------------------------------------------------------------------------------
create table absrec.posts (
    creation        time              not null,
    creator         bytea             not null,
    --------------- ----------------- ------------ -----------------------------------
    text            text              not null,
    --------------- ----------------- ------------ -----------------------------------
    forum_name      varchar(128)      not null,
    topic_creator   bytea             not null,
    topic_creation  time              not null,
    --------------- ----------------- ------------ -----------------------------------
    foreign key (forum_name,topic_creator,topic_creation) references absrec.topics(forum_name,creator,creation)
);
create unique index  absrec_topic_posts  absrec.posts(topic_creator,topic_creation,creation);
