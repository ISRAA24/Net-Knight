
const Notification = require('../models/notification');
const User         = require('../models/User');
const sendEmail    = require('./sendEmail');
const logger       = require('./logger');


let _broadcast = null;
const getBroadcast = () => {
    if (!_broadcast)
        _broadcast = require('../sockets/dashboard.socket').broadcastNotification;
    return _broadcast;
};


const buildEmailHtml = (username, notif) => {
    
    const config = {
        ai_rule_pending: {
            emoji:       '🤖',
            accentColor: '#f0a500',
            badgeBg:     '#f0a5001a',
            badgeText:   'Review Needed',
            headerLine:  'An AI-generated rule is waiting for your approval.'
        },
        threat_alert: {
            emoji:       '🚨',
            accentColor: notif.severity === 'critical' ? '#e94560' : '#ff6b35',
            badgeBg:     notif.severity === 'critical' ? '#e945601a' : '#ff6b351a',
            badgeText:   notif.tag || notif.severity,
            headerLine:  'A security threat has been detected on your network.'
        },
        traffic_spike: {
            emoji:       '⚡',
            accentColor: '#f0a500',
            badgeBg:     '#f0a5001a',
            badgeText:   'Warning',
            headerLine:  'Unusual network traffic has been detected.'
        }
    };

    const c = config[notif.type] || config.traffic_spike;

    
    const metaRows = buildMetaRows(notif);

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background:#0f0f1a;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0f0f1a;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="520" cellpadding="0" cellspacing="0"
               style="background:#1a1a2e;border-radius:16px;overflow:hidden;
                      border:1px solid #ffffff12;max-width:100%;">

          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#16213e,#0f3460);
                        padding:32px 32px 24px;text-align:center;">
              <div style="font-size:48px;margin-bottom:12px;">${c.emoji}</div>
              <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;
                          letter-spacing:0.5px;">${notif.title}</h1>
              <p style="margin:8px 0 0;color:#8b9cc8;font-size:14px;">
                ${c.headerLine}
              </p>
            </td>
          </tr>

          <!-- Badge -->
          <tr>
            <td style="padding:16px 32px 0;text-align:center;">
              <span style="display:inline-block;padding:6px 18px;border-radius:20px;
                            background:${c.badgeBg};color:${c.accentColor};
                            font-size:12px;font-weight:700;letter-spacing:1px;
                            border:1px solid ${c.accentColor}40;text-transform:uppercase;">
                ${c.badgeText}
              </span>
            </td>
          </tr>

          <!-- Message -->
          <tr>
            <td style="padding:24px 32px 0;">
              <div style="background:#ffffff08;border-left:3px solid ${c.accentColor};
                           border-radius:0 8px 8px 0;padding:14px 16px;">
                <p style="margin:0;color:#d0d8f0;font-size:15px;line-height:1.6;">
                  ${notif.message}
                </p>
              </div>
            </td>
          </tr>

          <!-- Meta details table -->
          ${metaRows ? `
          <tr>
            <td style="padding:20px 32px 0;">
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="background:#ffffff06;border-radius:8px;overflow:hidden;
                             border:1px solid #ffffff0f;">
                ${metaRows}
              </table>
            </td>
          </tr>` : ''}

          <!-- Greeting + timestamp -->
          <tr>
            <td style="padding:24px 32px;">
              <p style="margin:0 0 6px;color:#8b9cc8;font-size:13px;">
                Hello, <strong style="color:#c8d0e8;">${username}</strong> 👋
              </p>
              <p style="margin:0;color:#4a5280;font-size:12px;">
                ${new Date().toUTCString()}
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background:#12122a;padding:16px 32px;text-align:center;
                        border-top:1px solid #ffffff0f;">
              <p style="margin:0;color:#4a5280;font-size:12px;">
                🛡️ <strong style="color:#6b7db3;">Net-Knight</strong> Security Platform
                &nbsp;·&nbsp; This is an automated alert. Do not reply.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
};


const buildMetaRows = (notif) => {
    const m = notif.metadata || {};
    const rows = [];

    const row = (label, value) =>
        `<tr>
           <td style="padding:10px 16px;color:#8b9cc8;font-size:13px;
                       border-bottom:1px solid #ffffff08;width:40%;">${label}</td>
           <td style="padding:10px 16px;color:#d0d8f0;font-size:13px;
                       font-weight:600;border-bottom:1px solid #ffffff08;">${value}</td>
         </tr>`;

    if (notif.type === 'ai_rule_pending') {
        if (m.ip)     rows.push(row('IP Address', m.ip));
        if (m.action) rows.push(row('Action',     m.action.toUpperCase()));
        if (m.reason) rows.push(row('Reason',     m.reason));
    }

    if (notif.type === 'threat_alert') {
        if (m.sourceIp)   rows.push(row('Source IP',  m.sourceIp));
        if (m.attackType) rows.push(row('Attack Type', m.attackType));
        if (m.severity)   rows.push(row('Severity',   m.severity.toUpperCase()));
        if (m.confidence) rows.push(row('Confidence', `${m.confidence}%`));
    }

    if (notif.type === 'traffic_spike') {
        if (m.interface)        rows.push(row('Interface',         m.interface));
        if (m.direction)        rows.push(row('Direction',         m.direction));
        if (m.currentBandwidth) rows.push(row('Current Bandwidth', `${m.currentBandwidth} ${m.unit || 'Gbps'}`));
        if (m.threshold)        rows.push(row('Threshold',         `${m.threshold} ${m.unit || 'Gbps'}`));
    }

    if (!rows.length) return null;
    return rows.join('');
};


const emailSubjects = {
    ai_rule_pending: '⚠️ AI Rule Pending Review — Net-Knight',
    threat_alert:    '🚨 Threat Alert Detected — Net-Knight',
    traffic_spike:   '⚡ Unusual Traffic Spike — Net-Knight'
};


const sendEmailsToAllUsers = async (notif) => {
    try {
        const users = await User.find({ isVerified: true }, 'email username');
        if (!users.length) return;

        const subject = emailSubjects[notif.type] || '🔔 New Alert — Net-Knight';

        const emailTasks = users.map(user =>
            sendEmail({
                email:   user.email,
                subject,
                html:    buildEmailHtml(user.username, notif),
                message: notif.message // plain text fallback
            }).catch(err => {
                
                logger.warn(`Email to ${user.email} failed: ${err.message}`);
            })
        );

        
        Promise.allSettled(emailTasks).then(results => {
            const sent   = results.filter(r => r.status === 'fulfilled').length;
            const failed = results.filter(r => r.status === 'rejected').length;
            logger.info(`Notification emails: ${sent} sent, ${failed} failed`);
        });

    } catch (err) {
        logger.error(`sendEmailsToAllUsers error: ${err.message}`);
    }
};


const createNotification = async ({
    type, title, message, severity, tag,
    relatedId, relatedModel, metadata
}) => {
    try {
        const notif = await Notification.create({
            type,
            title,
            message,
            severity: severity || 'info',
            tag:      tag      || '',
            relatedId:    relatedId    || null,
            relatedModel: relatedModel || null,
            metadata:     metadata     || {}
        });

        // ② Socket.IO — non-blocking
        try { getBroadcast()(notif); }
        catch (socketErr) {
            logger.warn(`Socket broadcast failed: ${socketErr.message}`);
        }

        // ③ Emails — fully non-blocking (fire and forget)
        sendEmailsToAllUsers(notif);

        return notif;
    } catch (err) {
        logger.error(`createNotification failed: ${err.message}`);
        return null;
    }
};

module.exports = { createNotification };