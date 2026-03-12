{
    'name': 'Adomi Community',
    'version': '1.0',
    'category': 'Sales/Sales',
    'summary': 'Adomi community layer (OCA dependencies)',
    'description': """
        Adomi community layer that aggregates OCA/community addons installed as dependencies.
    """,
    'author': 'Adomi',
    'website': 'https://adomi.io',
    'depends': [
        # Web related addons
        'web_responsive',

        # Remove Odoo branding
        'remove_odoo_enterprise',
        'disable_odoo_online',
        'mail_debranding',
        'portal_debranding',
        'sale_portal_debranding',

        # Accounting addons
        'account_statement_base',
        'account_statement_import_base',
        'account_statement_import_online',
        'account_usability',
        'account_analytic_tag',

        # Pending upstream:
        # 'account_statement_import_online_plaid',
    ],
    'data': [],
    'installable': True,
    'application': True,
    'auto_install': True,
    'license': 'LGPL-3',
}
